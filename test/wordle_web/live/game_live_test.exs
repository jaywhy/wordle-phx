defmodule WordleWeb.GameLiveTest do
  use WordleWeb.ConnCase, async: true

  # When testing helpers, you may want to import Phoenix.HTML and
  # use functions such as safe_to_string() to convert the helper
  # result into an HTML string.
  # import Phoenix.HTML

  import Phoenix.LiveViewTest

  describe "continuing a game" do
    test "can leave and game and rejoin and keep your place", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?game=1234")

      view |> insert_guess("habit")

      {:ok, view, _html} = live(conn, "/?game=1234")

      assert has_element?(view, "#letter-1-1", "h")
      assert has_element?(view, "#letter-1-2", "a")
      assert has_element?(view, "#letter-1-3", "b")
      assert has_element?(view, "#letter-1-4", "i")
      assert has_element?(view, "#letter-1-5", "t")
    end
  end

  describe "keyboard" do
    test "keys are green when guess is in the right position", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)
      view |> insert_guess("habit")

      assert has_element?(view, "#key-h > button.bg-green-500")
    end

    test "keys are yellow when letter is in the word but not in the right position", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> insert_guess("abash")

      assert has_element?(view, "#key-h > button.bg-yellow-500")
    end

    test "keys are dark gray when letter isn't in the word and has been used", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> insert_guess("abash")

      assert has_element?(view, "#key-a > button.bg-gray-500")
    end

    test "keys can change color from yellow to green", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view
      |> insert_guess("abash")
      |> insert_guess("habit")

      assert has_element?(view, "#key-h > button.bg-green-500")
    end

    test "keys can't change color from green to yellow", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view
      |> insert_guess("habit")
      |> insert_guess("abash")

      assert has_element?(view, "#key-h > button.bg-green-500")
    end
  end

  describe "pressing backspace" do
    test "deletes a character", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view
      |> press_key("a")
      |> press_backspace()

      refute has_element?(view, "#letter-1-1", "a")
    end

    test "doesn't work if nothing is there", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> press_backspace()

      refute has_element?(view, "#letter-1-0")
    end
  end

  test "adds letters to board", %{conn: conn} do
    {:ok, view, _html} = start_game(conn)

    view |> press_keys("hello")

    assert has_element?(view, "#letter-1-1", "h")
    assert has_element?(view, "#letter-1-2", "e")
    assert has_element?(view, "#letter-1-3", "l")
    assert has_element?(view, "#letter-1-4", "l")
    assert has_element?(view, "#letter-1-5", "o")
  end

  test "can't overfill a row with letters", %{conn: conn} do
    {:ok, view, _html} = start_game(conn)

    view
    |> press_keys("helloz")

    refute has_element?(view, "#guess-row-1", ~r/z/)
  end

  describe "pressing enter" do
    test "without a full row doesn't work", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view
      |> insert_guess("hell")
      |> press_key("o")

      assert has_element?(view, "#guess-row-1", ~r/o/)
      refute has_element?(view, "#letter-2-1", ~r/o/)
    end

    test "with good word goes to next row", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view
      |> insert_guess("abash")
      |> press_keys("a")

      assert has_element?(view, "#guess-row-2", ~r/a/)
    end

    test "with a bad word doesn't work", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view
      |> insert_guess("aaaaa")
      |> press_keys("a")

      refute has_element?(view, "#guess-row-2", ~r/a/)
    end

    test "with a bad word pushs an event", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> insert_guess("aaaaa")

      assert_push_event(view, "bad-word", %{row: "guess-row-1"})
    end
  end

  describe "letter are colored" do
    test "green when in the right position", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> insert_guess("hello")

      assert has_element?(view, "#letter-1-1.bg-green-600")
    end

    test "yellow when the letter is present but in the wrong position", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> insert_guess("loser")

      assert has_element?(view, "#letter-1-1.bg-yellow-500")
      assert has_element?(view, "#letter-1-2.bg-yellow-500")
      assert has_element?(view, "#letter-1-4.bg-yellow-500")
    end

    test "gray when it's not a match", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> insert_guess("abash")

      assert has_element?(view, "#letter-1-1.bg-gray-500")
      assert has_element?(view, "#letter-1-2.bg-gray-500")
      assert has_element?(view, "#letter-1-3.bg-gray-500")
      assert has_element?(view, "#letter-1-4.bg-gray-500")
    end
  end

  describe "screen" do
    test "tells you when you've won", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> insert_guess("hello")

      assert has_element?(view, "#screen > h1", "won")
      assert has_new_game?(view)
    end

    test "when you win it colors the last row of letters", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> insert_guess("hello")

      assert has_element?(view, "#letter-1-1.bg-green-600")
      assert has_element?(view, "#letter-1-2.bg-green-600")
      assert has_element?(view, "#letter-1-3.bg-green-600")
      assert has_element?(view, "#letter-1-4.bg-green-600")
      assert has_element?(view, "#letter-1-5.bg-green-600")
    end
  end

  describe "when you lose" do
    test "tells you when you've lose", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> lose_game("abash")

      assert has_element?(view, "#screen > h1", "lost")
      assert has_new_game?(view)
    end

    test "still colors the last row of letters", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> lose_game("abash")

      assert has_element?(view, "#letter-6-5.bg-yellow-500")
    end

    test "tells you the correct word", %{conn: conn} do
      {:ok, view, _html} = start_game(conn)

      view |> lose_game("abash")

      assert has_element?(view, "#screen", "hello")
    end
  end

  defp start_game(conn) do
    live(conn, "/") |> follow_redirect(conn)
  end

  defp has_new_game?(view) do
    has_element?(view, "#screen button", "New Game")
  end

  defp lose_game(view, word) do
    view
    |> insert_guess(word)
    |> insert_guess(word)
    |> insert_guess(word)
    |> insert_guess(word)
    |> insert_guess(word)
    |> insert_guess(word)
  end

  defp insert_guess(view, guess) do
    view
    |> press_keys(guess)
    |> press_enter()
  end

  defp press_keys(view, keys) do
    keys |> String.codepoints() |> Enum.reduce(view, &press_key(&2, &1))
    view
  end

  defp press_key(view, key) do
    view |> element("[phx-value-letter='#{key}']") |> render_click()
    view
  end

  defp press_enter(view) do
    view |> press_key("Enter")
  end

  defp press_backspace(view) do
    view |> press_key("Backspace")
  end
end

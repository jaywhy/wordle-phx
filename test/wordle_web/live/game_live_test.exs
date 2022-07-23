defmodule WordleWeb.GameLiveTest do
  use WordleWeb.ConnCase, async: true

  # When testing helpers, you may want to import Phoenix.HTML and
  # use functions such as safe_to_string() to convert the helper
  # result into an HTML string.
  # import Phoenix.HTML

  import Phoenix.LiveViewTest

  describe "keyboard" do
    test "colors keys green when in the right position" do
    end
  end

  describe "pressing backspace" do
    test "deletes a character", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> press_key("a")
      |> press_backspace()

      refute has_element?(view, "#letter-1-1", "a")
    end

    test "doesn't work if nothing is there", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> press_backspace()

      refute has_element?(view, "#letter-1-0")
    end
  end

  test "adds letters to board", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view
    |> press_keys("hello")

    assert has_element?(view, "#letter-1-1", "h")
    assert has_element?(view, "#letter-1-2", "e")
    assert has_element?(view, "#letter-1-3", "l")
    assert has_element?(view, "#letter-1-4", "l")
    assert has_element?(view, "#letter-1-5", "o")
  end

  test "can't overfill a row with letters", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view
    |> press_keys("helloz")

    refute has_element?(view, "#guess-row-1", ~r/z/)
  end

  describe "pressing enter" do
    test "without a full row doesn't work", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> press_keys("hell")
      |> press_enter()
      |> press_key("o")

      assert has_element?(view, "#guess-row-1", ~r/o/)
      refute has_element?(view, "#letter-2-1", ~r/o/)
    end

    test "with good word goes to next row", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> press_keys("hello")
      |> press_enter()
      |> press_keys("a")

      assert has_element?(view, "#guess-row-2", ~r/a/)
    end

    test "with a bad word doesn't work", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> press_keys("aaaaa")
      |> press_enter()
      |> press_keys("a")

      refute has_element?(view, "#guess-row-2", ~r/a/)
    end

    test "with a bad word pushs an event", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> press_keys("aaaaa")
      |> press_enter()

      assert_push_event(view, "bad-word", %{row: "guess-row-1"})
    end
  end

  describe "letter are colored" do
    test "green when in the right position", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?test-word=hello")

      view
      |> press_keys("hello")
      |> press_enter()

      assert has_element?(view, "#letter-1-1.bg-green-600")
    end

    test "yellow when the letter is present but in the wrong position", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?test-word=hello")

      view
      |> press_keys("loser")
      |> press_enter()

      assert has_element?(view, "#letter-1-1.bg-yellow-500")
      assert has_element?(view, "#letter-1-2.bg-yellow-500")
      assert has_element?(view, "#letter-1-4.bg-yellow-500")
    end

    test "gray when it's not a match", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?test-word=hello")

      view
      |> press_keys("abash")
      |> press_enter()

      assert has_element?(view, "#letter-1-1.bg-gray-500")
      assert has_element?(view, "#letter-1-2.bg-gray-500")
      assert has_element?(view, "#letter-1-3.bg-gray-500")
      assert has_element?(view, "#letter-1-4.bg-gray-500")
    end
  end

  describe "screen" do
    test "tells you when you've won", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?test-word=hello")

      view
      |> press_keys("hello")
      |> press_enter()

      assert has_element?(view, "#screen > h1", "won")
      assert has_new_game?(view)
    end

    test "when you win it colors the last row of letters", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?test-word=hello")

      view
      |> press_keys("hello")
      |> press_enter()

      assert has_element?(view, "#letter-1-1.bg-green-600")
      assert has_element?(view, "#letter-1-2.bg-green-600")
      assert has_element?(view, "#letter-1-3.bg-green-600")
      assert has_element?(view, "#letter-1-4.bg-green-600")
      assert has_element?(view, "#letter-1-5.bg-green-600")
    end

    test "tells you when you've lost", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?test-word=hello")

      view |> lose_game("abash")

      assert has_element?(view, "#screen > h1", "lost")
      assert has_new_game?(view)
    end

    test "when you lose it still colors the last row of letters", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/?test-word=hello")

      view |> lose_game("abash")

      assert has_element?(view, "#letter-6-5.bg-yellow-500")
    end
  end

  defp has_new_game?(view) do
    has_element?(view, "#screen button", "New Game")
  end

  defp lose_game(view, word) do
    view
    |> press_keys(word)
    |> press_enter()
    |> press_keys(word)
    |> press_enter()
    |> press_keys(word)
    |> press_enter()
    |> press_keys(word)
    |> press_enter()
    |> press_keys(word)
    |> press_enter()
    |> press_keys(word)
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
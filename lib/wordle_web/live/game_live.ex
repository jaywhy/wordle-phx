defmodule WordleWeb.GameLive do
  use WordleWeb, :live_view

  alias Wordle.WordList

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> initialize_game_state

    {:ok, socket}
  end

  @impl true
  def handle_event("reset", _, socket) do
    socket =
      socket
      |> initialize_game_state()

    {:noreply, socket}
  end

  def handle_event(_, _, socket)
      when socket.assigns.game_state == :won do
    {:noreply, socket}
  end

  def handle_event("keyboard-press", %{"letter" => "Enter"}, socket)
      when socket.assigns.current_column >= 5 do
    socket =
      cond do
        game_won?(socket.assigns) ->
          socket
          |> assign(:game_state, :won)
          |> assign(:current_row, socket.assigns.current_row + 1)

        game_lost?(socket.assigns) ->
          socket |> assign(:game_state, :lost)

        bad_word?(socket.assigns) ->
          IO.puts("bad_word: #{current_guess(socket.assigns)}")
          socket |> assign(:game_state, :bad_word)

        true ->
          socket
          |> assign_current_guess_to_letters_used()
          |> assign(:current_row, socket.assigns.current_row + 1)
          |> assign(:current_column, 0)
      end

    {:noreply, socket}
  end

  # Backspace upto the first column.
  def handle_event("keyboard-press", %{"letter" => "Backspace"}, socket)
      when socket.assigns.current_column <= 0 do
    {:noreply, socket}
  end

  def handle_event("keyboard-press", %{"letter" => "Backspace"}, socket) do
    socket =
      socket
      |> assign(:current_column, socket.assigns.current_column - 1)

    socket =
      socket
      |> assign(
        :guesses,
        set_letter(socket.assigns, "")
      )

    {:noreply, socket}
  end

  # Can't hit enter until row is filled.
  def handle_event("keyboard-press", %{"letter" => "Enter"}, socket)
      when socket.assigns.current_column < 5 do
    {:noreply, socket}
  end

  def handle_event("keyboard-press", _params, socket)
      when socket.assigns.current_column >= 5 do
    {:noreply, socket}
  end

  def handle_event("keyboard-press", %{"letter" => "Enter"}, socket)
      when socket.assigns.current_row >= 6 do
    # Game is done
    {:noreply, socket}
  end

  def handle_event("keyboard-press", %{"letter" => letter}, socket) do
    IO.puts("letter: #{letter}")

    socket =
      socket
      |> assign(
        :guesses,
        set_letter(socket.assigns, letter)
      )
      |> assign(:current_column, socket.assigns.current_column + 1)

    IO.inspect(socket.assigns)
    {:noreply, socket}
  end

  def won(assigns) do
    ~H"""
      <div class="fixed w-96 opacity-95 text-center p-10 mx-auto justify-center rounded-xl border z-20 rounded border-gray-500 bg-white">
        <h1 class="text-2xl mb-4">You won!</h1>
      <.new_game />
      </div>
    """
  end

  def new_game(assigns) do
    ~H"""
      <button 
        class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        phx-click="reset"
      >
        New Game
      </button>
    """
  end

  defp initialize_game_state(socket) do
    socket
    |> assign(:game_state, :new)
    |> assign(:current_word, WordList.random_word())
    |> assign(:current_row, 0)
    |> assign(:current_column, 0)
    |> assign(:guesses, create_guesses())
    |> assign(:keyboard, create_keyboard())
    |> assign(:letters_used, MapSet.new())
  end

  defp letter_used?(letters_used, letter) do
    letters_used
    |> MapSet.member?(
      letter
      |> to_string()
      |> String.downcase()
    )
  end

  defp assign_current_guess_to_letters_used(socket) do
    socket
    |> assign(
      :letters_used,
      current_guess(socket.assigns)
      |> String.downcase()
      |> String.codepoints()
      |> MapSet.new()
      |> MapSet.union(socket.assigns.letters_used)
    )
  end

  defp game_won?(assigns),
    do: current_guess(assigns) == assigns.current_word

  defp game_lost?(assigns) do
    assigns.current_row >= 6 &&
      current_guess(assigns) != assigns.current_word
  end

  defp bad_word?(assigns) do
    current_guess(assigns) |> WordList.bad_word?()
  end

  defp current_guess(assigns) do
    assigns.guesses |> Enum.at(assigns.current_row) |> Enum.join("")
  end

  defp set_letter(assigns, letter) do
    guess =
      assigns.guesses
      |> Enum.at(assigns.current_row)
      |> List.replace_at(assigns.current_column, letter)

    assigns.guesses |> List.replace_at(assigns.current_row, guess)
  end

  defp create_guesses do
    guess_amount = 6
    word_length = 5

    for _i <- 1..guess_amount, into: [], do: create_guess(word_length)
  end

  defp create_guess(word_length) do
    for _i <- 1..word_length, into: [], do: ""
  end

  defp create_keyboard do
    [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['Enter', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'Backspace']
    ]
  end

  defp letter_classnames(guess, letter, position) do
    cond do
      guess |> String.at(position) == letter ->
        "bg-green-600 border-green-600 text-white"

      guess |> String.contains?(letter) ->
        "bg-yellow-500 border-yellow-500 text-white"

      true ->
        "bg-gray-500 border-gray-500 text-white"
    end
  end

  defp match_letter(letter) do
    letter
  end
end

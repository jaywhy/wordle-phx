defmodule WordleWeb.GameLive do
  use WordleWeb, :live_view

  import WordleWeb.Game
  import WordleWeb.Screens

  alias Wordle.WordList
  alias Wordle.Server

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Server.subscribe()

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
      when socket.assigns.current_column >= 6 do
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

          socket
          |> assign(:game_state, :bad_word)
          |> push_event("bad-word", %{row: guess_row_id(socket.assigns.current_row)})

        true ->
          socket
          |> assign_current_guess_to_letters_used()
          |> assign(:current_row, socket.assigns.current_row + 1)
          |> assign(:current_column, 1)
      end

    {:noreply, socket}
  end

  # Backspace upto the first column.
  def handle_event("keyboard-press", %{"letter" => "Backspace"}, socket)
      when socket.assigns.current_column <= 1 do
    {:noreply, socket}
  end

  # Backspace one column
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
      when socket.assigns.current_column < 6 do
    {:noreply, socket}
  end

  # Can't overfill a row. Ignore inputs.
  def handle_event("keyboard-press", _params, socket)
      when socket.assigns.current_column >= 6 do
    {:noreply, socket}
  end

  # Game is over. Ignore inputs.
  def handle_event("keyboard-press", _params, socket)
      when socket.assigns.current_row >= 7 do
    {:noreply, socket}
  end

  # Register keyboard press
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

  defp initialize_game_state(socket) do
    socket
    |> assign(:game_state, :new)
    |> assign(:current_word, WordList.random_word())
    |> assign(:current_row, 1)
    |> assign(:current_column, 1)
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
    IO.inspect(assigns)
    assigns.current_row >= 6 && !game_won?(assigns)
  end

  defp bad_word?(assigns) do
    current_guess(assigns) |> WordList.bad_word?()
  end

  defp guess_row_id(id) do
    "guess-row-#{id}"
  end

  defp current_guess(assigns) do
    assigns.guesses[assigns.current_row] |> Map.values() |> Enum.join("")
  end

  defp set_letter(assigns, letter) do
    put_in(assigns.guesses, [assigns.current_row, assigns.current_column], letter)
  end

  def create_guesses do
    guess_amount = 6
    word_length = 5

    for i <- 1..guess_amount, into: %{}, do: {i, create_guess(word_length)}
  end

  defp create_guess(word_length) do
    for i <- 1..word_length, into: %{}, do: {i, ""}
  end

  defp create_keyboard do
    [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['Enter', 'z', 'x', 'c', 'v', 'b', 'n', 'm', 'Backspace']
    ]
  end
end

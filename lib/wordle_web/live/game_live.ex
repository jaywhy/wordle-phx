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

    {:ok, socket, temporary_assigns: [guesses: %{}]}
  end

  @impl true
  def handle_params(%{"test-word" => word}, _url, socket) do
    {:noreply, assign(socket, :current_word, word)}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
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
          |> assign_carriage_return

        game_lost?(socket.assigns) ->
          socket
          |> assign(:game_state, :lost)
          |> assign_carriage_return

        bad_word?(socket.assigns.current_guess) ->
          socket
          |> assign(:game_state, :bad_word)
          |> push_event("bad-word", %{row: guess_row_id(socket.assigns.current_row)})

        true ->
          socket
          |> assign_current_guess_to_letters_used()
          |> assign_carriage_return()
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
    {:noreply, remove_letter(socket)}
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
    {:noreply, add_letter(socket, letter)}
  end

  defp assign_carriage_return(socket) do
    socket
    |> assign(:current_guess, "")
    |> assign(:guesses, %{
      socket.assigns.current_row => rerender_row(socket.assigns.current_guess)
    })
    |> assign(:current_row, socket.assigns.current_row + 1)
  end

  defp rerender_row(current_guess) do
    for {x, i} <- current_guess |> String.codepoints() |> Enum.with_index(),
        into: %{},
        do: {i + 1, x}
  end

  defp add_letter(socket, letter) do
    socket
    |> assign(:guesses, %{
      socket.assigns.current_row => %{socket.assigns.current_column => letter}
    })
    |> assign(:current_guess, socket.assigns.current_guess <> letter)
    |> assign(:current_column, socket.assigns.current_column + 1)
  end

  defp remove_letter(socket) do
    socket
    |> assign(:guesses, %{
      socket.assigns.current_row => %{(socket.assigns.current_column - 1) => ""}
    })
    |> assign(:current_column, socket.assigns.current_column - 1)
    |> assign(:current_guess, socket.assigns.current_guess |> String.slice(0..-2))
  end

  defp initialize_game_state(socket) do
    socket
    |> assign(:game_state, :new)
    |> assign(:current_word, WordList.random_word())
    |> assign(:current_guess, "")
    |> assign(:current_row, 1)
    |> assign(:current_column, 1)
    |> assign(:guesses, create_guesses())
    |> assign(:keyboard, create_keyboard())
    |> assign(:letters_used, create_letters_used())
  end

  defp assign_current_guess_to_letters_used(socket) do
    socket
    |> assign(
      :letters_used,
      update_letters_used(
        socket.assigns.letters_used,
        socket.assigns.current_guess,
        socket.assigns.current_word
      )
    )
  end

  def update_letters_used(letters_used, current_guess, current_word) do
    current_guess
    |> String.codepoints()
    |> Enum.with_index()
    |> Enum.reduce(letters_used, fn {key, position}, letters_used ->
      letters_used
      |> Map.update!(key, fn existing_value ->
        cond do
          existing_value == :match ->
            :match

          current_word |> String.at(position) == key ->
            :match

          current_word |> String.contains?(key) ->
            :contains

          true ->
            :used
        end
      end)
    end)
  end

  defp game_won?(assigns),
    do: assigns.current_guess == assigns.current_word

  defp game_lost?(assigns) do
    assigns.current_row >= 6 && !game_won?(assigns)
  end

  defp bad_word?(current_guess) do
    WordList.bad_word?(current_guess)
  end

  defp guess_row_id(id) do
    "guess-row-#{id}"
  end

  defp key(%{letter: "Backspace"} = assigns) do
    ~H"""
      <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
        <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2M3 12l6.414 6.414a2 2 0 001.414.586H19a2 2 0 002-2V7a2 2 0 00-2-2h-8.172a2 2 0 00-1.414.586L3 12z" />
      </svg>
    """
  end

  defp key(assigns) do
    ~H"""
    <%= assigns.letter %>
    """
  end

  defp key_classnames(letters_used, letter) do
    classnames =
      case letters_used[letter] do
        :match ->
          "bg-green-500 text-white "

        :used ->
          "bg-gray-500 text-white "

        :contains ->
          "bg-yellow-500 text-white "

        :unused ->
          "bg-gray-200 "

        _ ->
          "bg-gray-200 "
      end

    classnames <>
      "h-14 text-sm m-0.5 px-2.5 md:px-4 md:p-3 md:h-16 md:text-base md:m-1 font-bold uppercase rounded"
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
      ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
      ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
      ["Enter", "z", "x", "c", "v", "b", "n", "m", "Backspace"]
    ]
  end

  defp create_letters_used do
    ?a..?z
    |> Enum.to_list()
    |> List.to_string()
    |> String.codepoints()
    |> Map.new(&{&1, :unused})
  end
end

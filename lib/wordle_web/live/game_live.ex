defmodule WordleWeb.GameLive do
  use WordleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_word, "jason")
      |> assign(:current_guess, "")
      |> assign(:keyboard, create_keyboard())
      |> assign(:guesses, create_guesses())
      |> assign(:current_row, 0)
      |> assign(:current_column, 0)

    {:ok, socket}
  end

  @impl true
  def handle_event("keyboard-press", %{"letter" => "Enter"}, socket)
      when socket.assigns.current_column >= 5 do
    if game_won?(socket.assigns) do
      IO.puts("You've won!")
    end

    socket =
      socket
      |> assign(:current_row, socket.assigns.current_row + 1)
      |> assign(:current_column, 0)

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

    IO.puts("Backspace!!!!!!!!!!!!!")
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

  defp game_won?(assigns),
    do: current_guess(assigns.guesses, assigns.current_row) == assigns.current_word

  defp current_guess(guesses, current_row) do
    guesses |> Enum.at(current_row) |> Enum.join("")
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

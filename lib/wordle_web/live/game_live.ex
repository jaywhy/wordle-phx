defmodule WordleWeb.GameLive do
  use WordleWeb, :live_view

  import WordleWeb.Game
  import WordleWeb.Screens

  alias Wordle.GameState
  alias Wordle.Server

  @impl true
  def mount(%{"game" => uuid}, _session, socket) do
    if connected?(socket), do: subscribe(uuid)

    socket =
      if connected?(socket) do
        pid = Server.start_link(uuid)

        socket
        |> assign(:pid, pid)
        |> assign(Map.from_struct(Server.current_game_state(pid)))
      else
        socket
        |> assign(GameState.new_as_map(uuid))
      end

    socket =
      socket
      |> assign(:keyboard, create_keyboard())

    {:ok, socket, temporary_assigns: [board: %{}]}
  end

  def mount(_params, _session, socket) do
    {:ok, push_redirect(socket, to: "/?game=#{UUID.uuid1()}")}
  end

  @impl true
  def handle_event("reset", _, socket) do
    Wordle.Server.reset(socket.assigns.pid)
    {:noreply, socket}
  end

  def handle_event(_, _, socket)
      when socket.assigns.game_state == :won do
    {:noreply, socket}
  end

  def handle_event("keyboard-press", %{"letter" => "Enter"}, socket)
      when socket.assigns.current_column >= 6 do
    Wordle.Server.press_enter(socket.assigns.pid)
    {:noreply, socket}
  end

  # Backspace upto the first column.
  def handle_event("keyboard-press", %{"letter" => "Backspace"}, socket)
      when socket.assigns.current_column <= 1 do
    {:noreply, socket}
  end

  # Backspace one column
  def handle_event("keyboard-press", %{"letter" => "Backspace"}, socket) do
    Wordle.Server.remove_letter(socket.assigns.pid)
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
    Wordle.Server.add_letter(socket.assigns.pid, letter)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:update_state, changes}, socket) do
    {:noreply, assign(socket, changes)}
  end

  def handle_info({:bad_word, changes}, socket) do
    socket =
      socket
      |> push_event("bad-word", %{row: guess_row_id(socket.assigns.current_row)})
      |> assign(socket, changes)

    {:noreply, socket}
  end

  def subscribe(uuid) do
    Phoenix.PubSub.subscribe(Wordle.PubSub, "game:#{uuid}")
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
      "h-14 text-sm m-0.5 px-2.5 md:px-4 md:p-3 md:h-16 md:text-base md:m-1 font-bold uppercase rounded touch-manipulation"
  end

  defp create_keyboard do
    [
      ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
      ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
      ["Enter", "z", "x", "c", "v", "b", "n", "m", "Backspace"]
    ]
  end
end

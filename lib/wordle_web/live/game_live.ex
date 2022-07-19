defmodule WordleWeb.GameLive do
  use WordleWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:current_word, "jason")
      |> assign(:guesses, create_guesses())

    IO.inspect(socket.assigns.guesses)
    {:ok, socket}
  end

  defp create_guesses do
    guess_amount = 6
    word_length = 5

    for _i <- 1..guess_amount, into: [], do: create_guess(word_length)
  end

  defp create_guess(word_length) do
    for _i <- 1..word_length, into: [], do: ""
  end
end

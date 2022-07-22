defmodule Wordle.Server do
  def subscribe do
    Phoenix.PubSub.subscribe(Wordle.PubSub, "game")
  end

  def broadcast(event, payload) do
    Phoenix.PubSub.broadcast(Wordle.PubSub, "game", event, payload)
  end
end

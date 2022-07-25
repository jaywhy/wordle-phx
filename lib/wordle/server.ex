defmodule Wordle.Server do
  def subscribe(uuid) do
    Phoenix.PubSub.subscribe(Wordle.PubSub, "game:#{uuid}")
  end

  def broadcast(uuid, event), do: Phoenix.PubSub.broadcast(Wordle.PubSub, "game:#{uuid}", {event})

  def broadcast(uuid, event, payload) do
    Phoenix.PubSub.broadcast(Wordle.PubSub, "game:#{uuid}", {event, payload})
  end
end

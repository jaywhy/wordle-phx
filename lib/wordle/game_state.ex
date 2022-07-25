defmodule Wordle.GameState do
  use GenServer

  @name __MODULE__

  # Client

  def insert(uuid, game_state) do
    GenServer.call(__MODULE__, {:insert, uuid, game_state})
  end

  def lookup(uuid) do
    GenServer.call(__MODULE__, {:lookup, uuid})
  end

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: @name)

  # Server
  def init(_) do
    :ets.new(:game_state, [:set, :named_table, :public])
    {:ok, :created}
  end

  def handle_call({:insert, uuid, game_state}, _from, state) do
    :ets.insert(:game_state, {uuid, game_state})
    {:noreply, state}
  end

  def handle_call({:lookup, uuid}, _from, state) do
    :ets.lookup(:game_state, uuid)
    {:noreply, state}
  end
end

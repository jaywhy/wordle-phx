defmodule Wordle.ServerManager do
  use GenServer

  alias Wordle.Server

  # Client

  def start_link(_args), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def connect(uuid) do
    GenServer.call(__MODULE__, {:connect, uuid})
  end

  # Server

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:connect, uuid}, _from, state) do
    if(Map.has_key?(state, uuid)) do
      {:reply, Map.get(state, uuid), state}
    else
      {:ok, pid} = Server.start_link(uuid)
      {:reply, pid, Map.put(state, uuid, pid)}
    end
  end
end

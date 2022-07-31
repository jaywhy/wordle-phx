defmodule Wordle.Server do
  use GenServer

  alias Wordle.GameState
  alias Wordle.WordList

  # Client

  def start_link(uuid) do
    GenServer.start_link(__MODULE__, [uuid])
  end

  def add_letter(pid, letter) do
    GenServer.cast(pid, {:add_letter, letter})
  end

  def remove_letter(pid) do
    GenServer.cast(pid, {:remove_letter})
  end

  def press_enter(pid) do
    GenServer.cast(pid, {:press_enter})
  end

  def reset(pid) do
    GenServer.cast(pid, {:reset})
  end

  def current_game_state(pid) do
    GenServer.call(pid, :current_game_state)
  end

  # Server

  def init(uuid) do
    {:ok, GameState.new(uuid)}
  end

  def handle_call(:current_game_state, _from, game_state) do
    {:reply, game_state, game_state}
  end

  def handle_cast({:add_letter, letter}, game_state) do
    {:noreply, handle_add_letter(game_state, letter)}
  end

  def handle_cast({:remove_letter}, game_state) do
    {:noreply, handle_remove_letter(game_state)}
  end

  def handle_cast({:press_enter}, game_state) do
    {:noreply, handle_enter(game_state)}
  end

  def handle_cast({:reset}, game_state) do
    {:noreply, handle_reset(game_state)}
  end

  defp handle_add_letter(game_state, letter) do
    %{
      current_column: game_state.current_column + 1,
      board: %{game_state.current_row => %{game_state.current_column => letter}}
    }
    |> update_state(game_state)
  end

  defp handle_enter(game_state) do
    cond do
      GameState.game_won?(game_state) ->
        handle_winning(game_state)

      GameState.game_lost?(game_state) ->
        handle_losing(game_state)

      bad_word?(game_state) ->
        handle_bad_word(game_state)

      true ->
        handle_carriage_return(game_state)
    end
  end

  def handle_reset(game_state) do
    game_state = GameState.new(game_state.uuid)
    broadcast_changes(:update_state, game_state.uuid, Map.from_struct(game_state))
    game_state
  end

  defp handle_winning(game_state) do
    game_state
    |> carriage_return()
    |> Map.put(:game_state, :won)
    |> update_state(game_state)
  end

  defp handle_losing(game_state) do
    game_state
    |> carriage_return()
    |> Map.put(:game_state, :lost)
    |> update_state(game_state)
  end

  defp handle_bad_word(game_state) do
    %{game_state: :bad_word} |> update_state(game_state, :bad_word)
  end

  defp handle_carriage_return(game_state) do
    game_state
    |> carriage_return()
    |> update_state(game_state)
  end

  defp carriage_return(game_state) do
    %{
      board: %{game_state.current_row => GameState.carriage_return(game_state)},
      current_row: game_state.current_row + 1,
      letters_used: GameState.update_letters_used(game_state),
      current_column: 1
    }
  end

  defp update_state(changes, game_state), do: update_state(changes, game_state, :update_state)

  defp update_state(changes, game_state, event) do
    broadcast_changes(event, game_state.uuid, changes)
    GameState.new_from_changes(game_state, changes)
  end

  defp broadcast_changes(event, uuid, changes) do
    Phoenix.PubSub.broadcast(Wordle.PubSub, "game:#{uuid}", {event, changes})
  end

  defp bad_word?(game_state) do
    game_state
    |> GameState.current_guess()
    |> WordList.bad_word?()
  end

  defp handle_remove_letter(game_state) do
    game_state_changes = %{
      current_column: game_state.current_column - 1,
      board: %{game_state.current_row => %{(game_state.current_column - 1) => ""}}
    }

    broadcast_changes(:update_state, game_state.uuid, game_state_changes)

    game_state
    |> GameState.merge_changes(game_state_changes)
    |> GameState.new_from_map()
  end
end

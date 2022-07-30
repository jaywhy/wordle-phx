defmodule Wordle.GameState do
  alias Wordle.WordList

  defstruct [
    :uuid,
    :game_state,
    :current_word,
    :current_row,
    :current_column,
    :board,
    :letters_used
  ]

  def new(uuid) do
    %__MODULE__{
      uuid: uuid,
      game_state: :new,
      current_word: WordList.random_word(),
      current_row: 1,
      current_column: 1,
      board: initialize_board(),
      letters_used: initialize_letters_used()
    }
  end

  def new_as_map(uuid), do: new(uuid) |> Map.from_struct()

  def new_from_map(game_state_map) do
    struct(%__MODULE__{}, game_state_map)
  end

  def new_from_changes(game_state, game_state_changes) do
    game_state
    |> merge_changes(game_state_changes)
    |> new_from_map()
  end

  def current_guess(game_state) do
    game_state.board[game_state.current_row]
    |> Map.values()
    |> Enum.join()
  end

  def carriage_return(game_state) do
    game_state
    |> current_guess
    |> String.codepoints()
    |> Enum.with_index()
    |> Map.new(fn {letter, column} -> {column + 1, letter} end)
  end

  def game_won?(game_state),
    do: current_guess(game_state) == game_state.current_word

  def game_lost?(assigns) do
    assigns.current_row >= 6 && !game_won?(assigns)
  end

  def merge_changes(original, changes) do
    original
    |> Map.from_struct()
    |> Map.merge(changes, &merge/3)
  end

  def merge(_k, %{} = v1, %{} = v2) do
    Map.merge(v1, v2, &merge/3)
  end

  def merge(_k, _v1, v2), do: v2

  def update_letters_used(game_state) do
    game_state
    |> current_guess
    |> String.codepoints()
    |> Enum.with_index()
    |> Enum.reduce(game_state.letters_used, fn {key, position}, letters_used ->
      letters_used
      |> Map.update!(key, fn existing_value ->
        cond do
          existing_value == :match ->
            :match

          game_state.current_word |> String.at(position) == key ->
            :match

          game_state.current_word |> String.contains?(key) ->
            :contains

          true ->
            :used
        end
      end)
    end)
  end

  defp initialize_board do
    guess_amount = 6
    word_length = 5

    for i <- 1..guess_amount, into: %{}, do: {i, initialize_guess(word_length)}
  end

  defp initialize_guess(word_length) do
    for i <- 1..word_length, into: %{}, do: {i, ""}
  end

  defp initialize_letters_used do
    ?a..?z
    |> Enum.to_list()
    |> List.to_string()
    |> String.codepoints()
    |> Map.new(&{&1, :unused})
  end
end

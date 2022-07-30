defmodule Wordle.GameStateTest do
  use ExUnit.Case, async: true

  alias Wordle.GameState

  describe "new/1" do
    test "returns a struct with a uuid" do
      game_state = GameState.new("1234")
      assert game_state.uuid == "1234"
    end

    test "returns a struct with a random word" do
      game_state = GameState.new("1234")
      assert game_state.current_word |> String.length() == 5
    end

    test "initializes a board" do
      game_state = GameState.new("1234")
      assert game_state.board[5][5] == ""
    end

    test "initializes letters used" do
      game_state = GameState.new("1234")
      assert game_state.letters_used["a"] == :unused
      assert game_state.letters_used["z"] == :unused
    end
  end

  describe "game_won?" do
    test "returns true if the game has been won" do
      game_state = GameState.new(1234)

      game_state = %GameState{
        game_state
        | board: board_guess_at(game_state.current_word, game_state.current_row)
      }

      assert GameState.game_won?(game_state) == true
    end
  end

  describe "game_lost?" do
    test "returns true if the game has been lost" do
      game_state = GameState.new(1234)

      game_state = %GameState{
        game_state
        | board: board_guess_at("qwerty", 6),
          current_row: 6
      }

      assert GameState.game_lost?(game_state) == true
    end
  end

  describe "update_letters_used/3" do
    test "updates the letters used" do
      game_state = GameState.new(1234)
      game_state = %GameState{game_state | board: board_guess_at("cameo", 1)}

      letters_used = GameState.update_letters_used(game_state)

      assert letters_used["c"] == :used
      assert letters_used["a"] == :used
      assert letters_used["m"] == :used
      assert letters_used["e"] == :contains
      assert letters_used["o"] == :match
    end
  end

  defp board_guess_at(guess, position) do
    %{
      position =>
        guess
        |> String.codepoints()
        |> Enum.with_index()
        |> Map.new(fn {letter, column} -> {column + 1, letter} end)
    }
  end
end

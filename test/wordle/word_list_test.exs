defmodule Wordle.WordListTest do
  use ExUnit.Case, async: true

  alias Wordle.WordList

  describe "bad_word?/1" do
    test "returns true if the given word is not allowed" do
      assert WordList.bad_word?("aaaaa") == true
    end

    test "returns false if the given word is in the allowed word list" do
      assert WordList.bad_word?("abash") == false
    end

    test "returns false if the given word is in the word list" do
      assert WordList.bad_word?("hello") == false
    end
  end

  describe "random_word/1" do
    test "returns a random 5 letter word from the word list" do
      assert WordList.random_word() |> String.length == 5
    end

    test "returns a word that isn't a 'bad word'" do
      assert WordList.random_word() |> WordList.bad_word? == false
    end
  end
end

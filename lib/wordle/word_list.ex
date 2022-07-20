defmodule Wordle.WordList do
  def random_word do
    word_list_path()
    |> File.stream!()
    |> Enum.random()
    |> String.trim()
  end

  def bad_word?(word) do
    allowed_list_path()
    |> File.stream!()
    # Could be faster with a binary search. The list is ordered.
    |> Enum.any?(&(&1 == word))
  end

  defp word_list_path do
    "priv/word-list.txt"
  end

  defp allowed_list_path do
    "priv/allowed-list.txt"
  end
end

defmodule Wordle.WordList do
  def random_word do
    word_list_path()
    |> File.stream!()
    |> Enum.random()
    |> String.trim()
  end

  defp word_list_path do
    "priv/word-list.txt"
  end
end

defmodule Wordle.WordList do
  @allowed_list_path "priv/allowed-list.txt"
  @word_list_path "priv/word-list.txt"

  @word_list Wordle.LoadWordList.load(@allowed_list_path)
  @allowed_list @word_list_path
                |> File.stream!()
                |> Map.new(&{&1 |> String.trim(), true})

  def random_word() do
    @word_list |> Enum.random() |> elem(0)
  end

  def bad_word?(word) do
    !(@allowed_list |> Map.has_key?(word)) && !(@word_list |> Map.has_key?(word))
  end
end

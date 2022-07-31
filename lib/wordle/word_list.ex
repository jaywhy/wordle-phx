defmodule Wordle.WordList do
  @allowed_list_path "priv/allowed-list.txt"
  @word_list_path "priv/word-list.txt"

  @word_list Wordle.LoadWordList.load(@word_list_path)
  @allowed_list Wordle.LoadWordList.load(@allowed_list_path)

  def random_word() do
    if Application.get_env(:wordle, :environment) == :test do
      "hello"
    else
      @word_list |> Enum.random() |> elem(0)
    end
  end

  def bad_word?(word) do
    !(@allowed_list |> Map.has_key?(word)) && !(@word_list |> Map.has_key?(word))
  end
end

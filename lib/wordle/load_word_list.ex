defmodule Wordle.LoadWordList do
  def load(filename) do
    filename
    |> File.stream!()
    |> Map.new(&{&1 |> String.trim(), true})
  end
end

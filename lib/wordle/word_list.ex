defmodule Wordle.WordList do
  use GenServer

  # Client

  def random_word() do
    GenServer.call(__MODULE__, :random_word)
  end

  def bad_word?(word) do
    GenServer.call(__MODULE__, {:bad_word, word})
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server

  @impl true
  def init(_opts) do
    {:ok, %{allowed_list: load_allowed_list(), word_list: load_word_list()}}
  end

  @impl true
  def handle_call(:random_word, _from, %{word_list: word_list} = state) do
    {:reply, random_word(word_list), state}
  end

  def handle_call(
        {:bad_word, word},
        _from,
        %{allowed_list: allowed_list, word_list: word_list} = state
      ) do
    {:reply, !(allowed_list |> Map.has_key?(word)) && !(word_list |> Map.has_key?(word)), state}
  end

  defp random_word(list) do
    list |> Enum.random() |> elem(0)
  end

  defp load_allowed_list do
    allowed_list_path()
    |> File.stream!()
    |> Map.new(&{&1 |> String.trim(), true})
  end

  defp load_word_list do
    word_list_path()
    |> File.stream!()
    |> Map.new(&{&1 |> String.trim(), true})
  end

  defp word_list_path do
    "priv/word-list.txt"
  end

  defp allowed_list_path do
    "priv/allowed-list.txt"
  end
end

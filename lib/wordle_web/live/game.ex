defmodule WordleWeb.Game do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  def board(assigns) do
    ~H"""
      <%= for {row, guess} <- @guesses do %>
      <div id={"guess-row-#{row}"}
          class="flex"
        phx-update="append"
          data-bad-word={row |> shake_it_off()}
      >
        <%= for {column, letter} <- guess do %>
          <div id={"letter-#{row}-#{column}"} class={"#{if row < @current_row, do: letter_classnames(@current_word, letter, column), else: " border-gray-300"} flex items-center justify-center m-0.5 w-16 h-16 border-2 text-4xl font-bold uppercase"}>
            <%= letter %>
          </div>
        <% end %>
        </div>
      <% end %>
    """
  end

  defp row(assigns) do
    ~H"""
      <div id={"guess-row-#{@id}"}
          class="flex"
          data-bad-word={@id |> shake_it_off()}
      >
        <%= for {column, letter} <- @guess do %>
          <%= render_slot(@inner_block, %{letter: letter, column: column}) %>
        <% end %>
      </div>
    """
  end

  defp letter(assigns) do
    ~H"""
      <div id={"letter-#{@row}-#{@column}"} class={"#{if @row < @current_row, do: letter_classnames(@current_word, @letter, @column), else: " border-gray-300"} flex items-center justify-center m-0.5 w-16 h-16 border-2 text-4xl font-bold uppercase"}>
        <%= @letter %>
      </div>
    """
  end

  defp shake_it_off(js \\ %JS{}, id) do
    JS.transition(
      js,
      "bg-red-100 shake",
      time: 500,
      to: "##{id}"
    )
  end

  defp guess_row_id(id) do
    "guess-row-#{id}"
  end

  defp letter_classnames(_guess, "", _), do: ""

  defp letter_classnames(guess, letter, position) do
    cond do
      guess |> String.at(position - 1) == letter ->
        " bg-green-600 text-white"

      guess |> String.contains?(letter) ->
        " bg-yellow-500 text-white"

      true ->
        " bg-gray-500 text-white"
    end
  end
end

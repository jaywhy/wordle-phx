defmodule WordleWeb.Screens do
  use Phoenix.Component

  def won(assigns) do
    ~H"""
      <div id="screen" class="fixed w-96 opacity-95 text-center p-10 mx-auto justify-center rounded-xl border z-20 rounded border-gray-500 bg-white">
        <h1 class="text-2xl mb-4">You won!</h1>
        <.new_game />
      </div>
    """
  end

  def lost(assigns) do
    ~H"""
      <div id="screen" class="fixed w-96 opacity-95 text-center p-10 mx-auto justify-center rounded-xl border z-20 rounded border-gray-500 bg-white">
        <h1 class="text-2xl mb-4">You lost!</h1>
        <p class="mb-1"> The correct word was <span class="font-bold"><%= @word %></span></p>
        <.new_game />
      </div>
    """
  end

  def new_game(assigns) do
    ~H"""
      <button 
        class="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        phx-click="reset"
      >
        New Game
      </button>
    """
  end
end

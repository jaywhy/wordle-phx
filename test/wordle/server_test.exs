defmodule Wordle.ServerTest do
  use ExUnit.Case, async: true

  alias Wordle.Server

  setup do
    {:ok, pid} = Server.start_link("server-test")
    %{server: pid}
  end

  describe "add_letter/2" do
    test "adds a letter to the board", %{server: server} do
      Server.add_letter(server, "a")

      game_state = Server.current_game_state(server)

      assert game_state.board[1][1] == "a"
    end
  end
end

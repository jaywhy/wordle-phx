defmodule Wordle.Repo do
  use Ecto.Repo,
    otp_app: :wordle,
    adapter: Ecto.Adapters.Postgres
end

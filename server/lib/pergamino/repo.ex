defmodule Pergamino.Repo do
  use Ecto.Repo,
    otp_app: :pergamino,
    adapter: Ecto.Adapters.Postgres
end

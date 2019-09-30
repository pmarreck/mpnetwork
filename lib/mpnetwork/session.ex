defmodule Mpnetwork.Session do
  import Ecto.Query
  alias Mpnetwork.{Config, Repo}
  alias Mpnetwork.Schema.Session

  def delete_old_sessions(), do: delete_old_sessions(Config.get(:default_session_expiry))
  def delete_old_sessions(opts) do
    ago = NaiveDateTime.utc_now() |> Timex.shift(opts)
    #select all sessions whose created_at is older than the configured duration
    from(
      s in Session,
      where: s.inserted_at < ^ago
    )
    |> Repo.delete_all
  end

end

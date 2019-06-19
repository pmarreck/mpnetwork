defmodule Mpnetwork.Repo do
  use Ecto.Repo, otp_app: :mpnetwork

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  EDIT: 6/19/2019: moved back to env config which THEN reads from the right environment variable.
  """
  def init(_, opts) do
    {:ok, opts}
  end
end

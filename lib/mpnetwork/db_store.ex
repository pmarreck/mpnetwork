defimpl Coherence.DbStore, for: Mpnetwork.User do
  alias Mpnetwork.Repo
  alias Mpnetwork.Ecto.DbSession

  def get_user_data(user, creds, id_key),
    do: DbSession.get_user_data(Repo, user, creds, id_key)

  def put_credentials(user, creds, id_key),
    do: DbSession.put_credentials(Repo, user, creds, id_key)

  def delete_credentials(user, creds),
    do: DbSession.delete_credentials(user, creds)

  def delete_user_logins(user),
    do: DbSession.delete_user_logins(user)
end

# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Mpnetwork.Repo.insert!(%Mpnetwork.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

case Mix.env do
  :prod ->
    raise "Cannot re-seed the production database!"
  _     ->
    Mpnetwork.Repo.delete_all Mpnetwork.User

    Mpnetwork.User.changeset(%Mpnetwork.User{}, %{username: "testuser", email: "testuser@example.com", office_id: 1, password: "secret", password_confirmation: "secret"})
    |> Mpnetwork.Repo.insert!
    |> Coherence.ControllerHelpers.confirm!
end

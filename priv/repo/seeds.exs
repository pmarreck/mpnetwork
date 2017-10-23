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

if (Mix.env == :prod) && (System.argv != ["confirm"]) do
  raise "Cannot re-seed the production database unless you pass in the argument 'confirm' via '-- confirm'!"
else
  Mpnetwork.Repo.delete_all Mpnetwork.Realtor.Office
  Mpnetwork.Repo.delete_all Mpnetwork.User
  oid = Mpnetwork.Realtor.Office.changeset(%Mpnetwork.Realtor.Office{}, %{name: "Coach Realtors", address: "321 Plandome Rd.", city: "Manhasset", state: "NY", zip: "11030", phone: "(516) 627-0120"}) |> Mpnetwork.Repo.insert!
  pw = "OdsPYMk8SY3CYBKADb1k0NKfwj6bW73tQQ"
  user = Mpnetwork.User.changeset(%Mpnetwork.User{}, %{name: "Admin", username: "admin", email: "admin@mpwrealestateboard.network", office_id: oid.id, role_id: 1, password: pw, password_confirmation: pw}) |> Mpnetwork.Repo.insert!
end

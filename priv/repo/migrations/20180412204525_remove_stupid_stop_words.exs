defmodule Mpnetwork.Repo.Migrations.RemoveStupidStopWords do
  use Ecto.Migration

  # The point of this is the fact that currently, "no" is considered a stop word in postgres fulltext indexing.
  # Call it my opinion, but this is idiotic as it prevents proper searching for things like "no pets"
  # It is impossible to edit the list via pure SQL and also to ssh into Google Cloud Postgres to
  # edit the file, so I'm just going to not use stop words for now and index everything.
  # You will know it worked when SELECT to_tsquery('english', 'no:A'); actually returns something.

  @up_statements [
    "ALTER TEXT SEARCH DICTIONARY english_stem ( StopWords );",
    "UPDATE listings SET address = address;"
  ]
  @down_statements [
    "ALTER TEXT SEARCH DICTIONARY english_stem ( StopWords = english );",
    "UPDATE listings SET address = address;"
  ]
  def up do
    @up_statements
    |> Enum.each(&execute/1)
  end
  def down do
    @down_statements
    |> Enum.each(&execute/1)
  end
end

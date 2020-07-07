defmodule MpnetworkWeb.InvitationWorkflowTest do
  use MpnetworkWeb.ConnCase, async: true
  alias Mpnetwork.Coherence.Invitation

  import Mpnetwork.Test.Support.Utilities

  # alias Mpnetwork.Realtor

  defp login_an_office_admin(conn) do
    user = user_fixture(%{role_id: 2})
    conn = assign(conn, :current_office, user.broker)
    conn = assign(conn, :current_user, user)
    {conn, user}
  end

  def to_map(attrs) when is_list(attrs), do: Enum.into(attrs, %{})
  def to_map(attrs) when is_map(attrs), do: attrs

  defp insert_invitation(attrs \\ %{}) do
    token = random_string(48)

    changes =
      Map.merge(
        %{
          name: "Test User",
          email: "user#{Base.encode16(:crypto.strong_rand_bytes(8))}@example.com",
          token: token
        },
        to_map(attrs)
      )

    %Invitation{}
    |> Invitation.changeset(changes)
    |> Mpnetwork.Repo.insert!()
  end

  setup %{conn: conn} do
    {conn, user} = login_an_office_admin(conn)
    {:ok, conn: conn, user: user}
  end

  test "can invite new user", %{conn: conn} do
    params = %{"invitation" => %{"name" => "John Doe", "email" => "john@example.com"}}
    conn = post(conn, invitation_path(conn, :create), params)
    assert get_flash(conn, :info) =~ "Invitation sent"
    # assert conn.private[:phoenix_flash] == %{"info" => "Invitation sent."}
    assert html_response(conn, 302)
  end

  test "can register as a new user from an invitation", %{conn: conn} do
    original_office = conn.assigns.current_office
    # create invitation (or just put a code into the db somehow, check coherence's own tests)
    invitation = insert_invitation()
    token = invitation.token
    # registration is actually under /invitations/:id/edit and should not be authenticated
    conn = assign(conn, :current_user, nil)
    conn = assign(conn, :current_office, nil)
    unauthenticated_conn = conn
    conn = get(conn, invitation_path(conn, :edit, token))
    assert html_response(conn, 200)
    conn = unauthenticated_conn

    params = %{
      "token" => token,
      "user" => %{
        "name" => "John Doe",
        "email" => "john#{random_string(12)}@example.com",
        "password" => "fupa",
        "password_confirmation" => "fupa",
        "office_id" => original_office.id
      }
    }

    conn = post(conn, invitation_path(conn, :create_user), params)
    # if it redirected, it was successful
    assert html_response(conn, 302)
  end
end

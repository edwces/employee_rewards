defmodule EmployeeRewardsWeb.MemberController do
  alias EmployeeRewards.Members
  use EmployeeRewardsWeb, :controller

  def index(conn, _params) do
    members = Members.list_members()
    render(conn, "index.html", members: members)
  end

  def grant(conn, %{"id" => member_id}) do
    member = Members.get_member!(member_id)
    changeset = Members.change_member(member)
    render(conn, "grant.html", member: member, changeset: changeset)
  end

  # HACK: We should probably not use custom form helpers this way
  # Either way add remove this page and grant and this functionality into index
  # Or add custom input helper in View Module
  def change(conn, %{"id" => member_id, "member" => member}) do
    from = conn.assigns.current_member
    to = Members.get_member!(member_id)
    # TODO: Handle this error if value isn't parsable or doesn't exist
    {points, _rem} = member |> Map.get("points") |> Integer.parse()

    case Members.transfer_member_points(from, to, %{points: points}) do
      {:ok, _changed} ->
        conn
        |> put_flash(:info, "Succesfully granted points")
        |> redirect(to: Routes.member_path(conn, :index))

      {:error, :member_from, %Ecto.Changeset{} = changeset, _changes} ->
        render(conn, "grant.html", member: to, changeset: changeset)
    end
  end
end

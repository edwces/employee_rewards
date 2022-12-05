defmodule EmployeeRewardsWeb.MemberController do
  alias EmployeeRewards.Members
  use EmployeeRewardsWeb, :controller

  def index(conn, _params) do
    members = Members.list_members()
    render(conn, "index.html", members: members)
  end

  def transfer(conn, %{"id" => member_id}) do
    member = Members.get_member!(member_id)
    render(conn, "transfer.html", member: member)
  end

  defguard is_positive(num) when is_integer(num) and num > 0
  # HACK: We should probably not use custom form helpers this way
  # Either way add remove this page and grant and this functionality into index
  # Or add custom input helper in View Module
  def change(conn, %{"id" => member_id, "points" => points}) do
    from = conn.assigns.current_member
    to = Members.get_member!(member_id)
    # REFACTOR: Nested case statement
    case Integer.parse(points) do
      {points, _rem} when is_positive(points) ->
        case Members.transfer_member_points(from, to, %{points: points}) do
          {:ok, _changed} ->
            conn
            |> put_flash(:info, "Succesfully granted points")
            |> redirect(to: Routes.member_path(conn, :index))

          {:error, :member_from, _changeset, _changes} ->
            render(conn, "transfer.html",
              member: to,
              errors: [points: {"Not enough points to transfer", []}]
            )

          {:error, :member_to, _changeset, _changes} ->
            render(conn, "transfer.html",
              member: to,
              errors: [points: {"Something went wrong", []}]
            )
        end

      {_points, _rem} ->
        render(conn, "transfer.html",
          member: to,
          errors: [points: {"Points must be a positive value", []}]
        )

      _ ->
        render(conn, "transfer.html",
          member: to,
          errors: [points: {"Points are not passed with correct format", []}]
        )
    end
  end
end

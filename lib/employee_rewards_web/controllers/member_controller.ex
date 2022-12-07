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

  defp put_errors(conn, errors) do
    errors = Enum.map(errors, fn {key, msg} -> {key, {msg, []}} end)
    Plug.Conn.assign(conn, :errors, errors)
  end

  # HACK: We should probably not use custom form helpers this way
  # Either way add remove this page and grant and this functionality into index
  # Or add custom input helper in View Module
  # TODO: Handle making transfer making to transfer to myself an error and
  # not finding "to" member
  def change(conn, %{"id" => member_id, "points" => points}) do
    from = conn.assigns.current_member
    to = Members.get_member!(member_id)

    with false <- from.id == to.id,
         {parsed, _rem} when is_positive(parsed) <- Integer.parse(points),
         {:ok, _changed} <- Members.transfer_member_points(from, to, %{points: parsed}) do
      conn
      |> put_flash(:info, "Succesfully granted points")
      |> redirect(to: Routes.member_path(conn, :index))
    else
      {:error, :member_from, _changeset, _changes} ->
        conn
        |> put_errors(points: "Not enough points to transfer")
        |> render("transfer.html", member: to)

      {parsed, _rem} when is_integer(parsed) ->
        conn
        |> put_errors(points: "Points must be a positive number")
        |> render("transfer.html", member: to)

      :error ->
        conn
        |> put_errors(points: "Must specify correct format for points")
        |> render("transfer.html", member: to)

      _ ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> render("transfer.html", member: to)
    end
  end
end

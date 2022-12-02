defmodule EmployeeRewardsWeb.MemberController do
  alias EmployeeRewards.Members
  use EmployeeRewardsWeb, :controller

  def index(conn, _params) do
    members = Members.list_members()
    render(conn, "index.html", members: members)
  end

  def grant(conn, _params) do
    members = Members.list_members()
    render(conn, "index.html", members: members)
  end
end

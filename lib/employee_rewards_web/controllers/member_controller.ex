defmodule EmployeeRewardsWeb.MemberController do
  use EmployeeRewardsWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

defmodule EmployeeRewardsWeb.RoleAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias EmployeeRewardsWeb.Router.Helpers, as: Routes

  def require_admin_role(conn, _opts) do
    if conn.assigns[:current_admin] do
      conn
    else
      conn
      |> put_flash(:error, "You need to be an admin to see this page")
      |> redirect(to: Routes.member_path(conn, :index))
      |> halt()
    end
  end
end

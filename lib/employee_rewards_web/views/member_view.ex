defmodule EmployeeRewardsWeb.MemberView do
  use EmployeeRewardsWeb, :view

  def get_errors(%Plug.Conn{assigns: %{errors: errors}}) when is_list(errors),
    do: errors

  def get_errors(_), do: []

  def errors?(%Phoenix.HTML.Form{errors: [_ | _]}),
    do: true

  def errors?(_), do: false
end

defmodule EmployeeRewards.AdminsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EmployeeRewards.Admins` context.
  """
  alias EmployeeRewards.IdentityFixtures

  def valid_admin_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      first_name: "Bob",
      last_name: "Adminer",
      credentials: IdentityFixtures.valid_credentials_attributes()
    })
  end

  @doc """
  Generate a admin.
  """
  def admin_fixture(attrs \\ %{}) do
    {:ok, admin} =
      attrs
      |> valid_admin_attributes()
      |> EmployeeRewards.Admins.register_admin()

    admin
  end
end

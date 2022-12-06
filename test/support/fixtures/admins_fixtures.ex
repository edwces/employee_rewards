defmodule EmployeeRewards.AdminsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EmployeeRewards.Admins` context.
  """

  @doc """
  Generate a admin.
  """
  def admin_fixture(attrs \\ %{}) do
    {:ok, admin} =
      attrs
      |> Enum.into(%{

      })
      |> EmployeeRewards.Admins.create_admin()

    admin
  end
end

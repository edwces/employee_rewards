defmodule EmployeeRewards.MembersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EmployeeRewards.Members` context.
  """
  alias EmployeeRewards.IdentityFixtures

  def valid_member_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      first_name: "John",
      last_name: "Shmoe",
      credentials: IdentityFixtures.valid_credentials_attributes()
    })
  end

  @doc """
  Generate a member.
  """
  def member_fixture(attrs \\ %{}) do
    {:ok, member} =
      attrs
      |> valid_member_attributes()
      |> EmployeeRewards.Members.register_member()

    member
  end
end

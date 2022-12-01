defmodule EmployeeRewards.MembersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EmployeeRewards.Members` context.
  """

  @doc """
  Generate a member.
  """
  def member_fixture(attrs \\ %{}) do
    {:ok, member} =
      attrs
      |> Enum.into(%{

      })
      |> EmployeeRewards.Members.create_member()

    member
  end
end

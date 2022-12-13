defmodule EmployeeRewards.RewardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EmployeeRewards.Rewards` context.
  """
  alias EmployeeRewards.MembersFixtures

  def valid_reward_attributes(attrs \\ %{}) do
    member = MembersFixtures.member_fixture()

    Enum.into(attrs, %{amount: 5, member: member})
  end

  @doc """
  Generate a reward.
  """
  def reward_fixture(attrs \\ %{}) do
    {:ok, reward} =
      attrs
      |> valid_reward_attributes()
      |> EmployeeRewards.Rewards.create_reward()

    reward
  end
end

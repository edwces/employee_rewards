defmodule EmployeeRewards.RewardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EmployeeRewards.Rewards` context.
  """

  @doc """
  Generate a reward.
  """
  def reward_fixture(attrs \\ %{}) do
    {:ok, reward} =
      attrs
      |> Enum.into(%{
        amount: 42
      })
      |> EmployeeRewards.Rewards.create_reward()

    reward
  end
end

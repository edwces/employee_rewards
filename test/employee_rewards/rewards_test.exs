defmodule EmployeeRewards.RewardsTest do
  use EmployeeRewards.DataCase

  alias EmployeeRewards.Rewards

  describe "rewards" do
    alias EmployeeRewards.Rewards.Reward

    import EmployeeRewards.RewardsFixtures

    @invalid_attrs %{amount: nil}

    test "list_rewards/0 returns all rewards" do
      reward = reward_fixture()
      assert Rewards.list_rewards() == [reward]
    end

    test "get_reward!/1 returns the reward with given id" do
      reward = reward_fixture()
      assert Rewards.get_reward!(reward.id) == reward
    end

    test "create_reward/1 with valid data creates a reward" do
      valid_attrs = %{amount: 42}

      assert {:ok, %Reward{} = reward} = Rewards.create_reward(valid_attrs)
      assert reward.amount == 42
    end

    test "create_reward/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rewards.create_reward(@invalid_attrs)
    end

    test "update_reward/2 with valid data updates the reward" do
      reward = reward_fixture()
      update_attrs = %{amount: 43}

      assert {:ok, %Reward{} = reward} = Rewards.update_reward(reward, update_attrs)
      assert reward.amount == 43
    end

    test "update_reward/2 with invalid data returns error changeset" do
      reward = reward_fixture()
      assert {:error, %Ecto.Changeset{}} = Rewards.update_reward(reward, @invalid_attrs)
      assert reward == Rewards.get_reward!(reward.id)
    end

    test "delete_reward/1 deletes the reward" do
      reward = reward_fixture()
      assert {:ok, %Reward{}} = Rewards.delete_reward(reward)
      assert_raise Ecto.NoResultsError, fn -> Rewards.get_reward!(reward.id) end
    end

    test "change_reward/1 returns a reward changeset" do
      reward = reward_fixture()
      assert %Ecto.Changeset{} = Rewards.change_reward(reward)
    end
  end
end

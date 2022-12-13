defmodule EmployeeRewards.RewardsTest do
  use EmployeeRewards.DataCase

  alias EmployeeRewards.MembersFixtures
  alias EmployeeRewards.Rewards

  describe "rewards" do
    alias EmployeeRewards.Rewards.Reward

    import EmployeeRewards.RewardsFixtures

    @invalid_attrs %{amount: nil, member: nil}

    test "list_rewards/0 returns all rewards" do
      reward = reward_fixture()
      assert Enum.map(Rewards.list_rewards(), fn reward -> reward.id end) == [reward.id]
    end

    test "get_reward!/1 returns the reward with given id" do
      reward = reward_fixture()
      assert Rewards.get_reward!(reward.id).id == reward.id
    end

    test "create_reward/1 with valid data creates a reward" do
      valid_attrs = valid_reward_attributes()

      assert {:ok, %Reward{} = reward} = Rewards.create_reward(valid_attrs)
      assert reward.amount == 5
    end

    test "create_reward/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rewards.create_reward(@invalid_attrs)
    end

    test "update_reward/2 with valid data updates the reward" do
      reward = reward_fixture()
      member = MembersFixtures.member_fixture()
      update_attrs = %{amount: 43, member: member}

      assert {:ok, %Reward{} = reward} = Rewards.update_reward(reward, update_attrs)
      assert reward.amount == 43
    end

    test "update_reward/2 with invalid data returns error changeset" do
      reward = reward_fixture()
      assert {:error, %Ecto.Changeset{}} = Rewards.update_reward(reward, @invalid_attrs)
      assert reward.id == Rewards.get_reward!(reward.id).id
    end

    test "delete_reward/1 deletes the reward" do
      reward = reward_fixture()
      assert {:ok, %Reward{}} = Rewards.delete_reward(reward)
      assert_raise Ecto.NoResultsError, fn -> Rewards.get_reward!(reward.id) end
    end

    test "change_reward/1 returns a reward changeset" do
      member = MembersFixtures.member_fixture()
      reward = reward_fixture()
      assert %Ecto.Changeset{} = Rewards.change_reward(reward, %{member: member})
    end
  end
end

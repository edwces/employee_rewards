defmodule EmployeeRewards.MembersTest do
  use EmployeeRewards.DataCase

  alias EmployeeRewards.RewardsFixtures
  alias EmployeeRewards.Rewards
  alias EmployeeRewards.Members

  describe "members" do
    alias EmployeeRewards.Members.Member

    import EmployeeRewards.MembersFixtures

    @invalid_attrs %{}
    @points_update_attrs %{points: 20}
    @pool_update_attrs %{pool: 20}
    @transfer_points_attrs %{points: 5}

    test "list_members/0 returns all members" do
      member = member_fixture()
      assert Enum.map(Members.list_members(), fn member -> member.id end) == [member.id]
    end

    test "get_member!/1 returns the member with given id" do
      member = member_fixture()
      assert Members.get_member!(member.id).id == member.id
    end

    test "register_member/1 with valid data creates a member" do
      valid_attrs = valid_member_attributes()

      assert {:ok, %Member{}} = Members.register_member(valid_attrs)
    end

    test "register_member/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Members.register_member(@invalid_attrs)
    end

    test "delete_member/1 deletes the member" do
      member = member_fixture()
      assert {:ok, %Member{}} = Members.delete_member(member)
      assert_raise Ecto.NoResultsError, fn -> Members.get_member!(member.id) end
    end

    test "change_member/1 returns a member changeset" do
      member = member_fixture()
      assert %Ecto.Changeset{} = Members.change_member(member)
    end

    test "change_member_points/2 returns a valid member changeset" do
      member = member_fixture()
      changeset = Members.change_member_points(member, @points_update_attrs)
      assert %Ecto.Changeset{} = changeset
      assert changeset.valid?
    end

    test "change_member_pool/2 returns a valid member changeset" do
      member = member_fixture()
      changeset = Members.change_member_pool(member, @pool_update_attrs)
      assert %Ecto.Changeset{} = changeset
      assert changeset.valid?
    end

    test "get_member_by_credentials/1 with valid data returns a member with given credentials" do
      member = member_fixture()
      assert Members.get_member_by_credentials(member.credentials).id == member.id
    end

    test "reset_members_points/0 updates all members" do
      member_fixture()
      assert {1, nil} = Members.reset_members_points()
    end

    test "reset_members_points/0 sets all member pools to 50" do
      member = member_fixture()
      Members.reset_members_points()
      assert Members.get_member!(member.id).pool == 50
    end

    test "transfer_member_points/3 with valid data perform a points transfer" do
      member_from = member_fixture(@pool_update_attrs)
      member_to = member_fixture()

      assert {:ok, %{member_to: to, member_from: from}} =
               Members.transfer_member_points(member_from, member_to, @transfer_points_attrs)

      assert from.pool == member_from.pool - @transfer_points_attrs.points
      assert to.points == member_to.points + @transfer_points_attrs.points
    end

    test "transfer_member_points/3 creates Reward entry" do
      member_from = member_fixture(@pool_update_attrs)
      member_to = member_fixture()

      assert {:ok, %{create_reward_entry: reward}} =
               Members.transfer_member_points(member_from, member_to, @transfer_points_attrs)

      assert %Rewards.Reward{} = reward
    end

    test "list_members_with_rewards/0 returns all members with their associated reward entries" do
      reward = RewardsFixtures.reward_fixture()
      result = Members.list_members_with_rewards()

      assert Enum.map(result, fn member -> member.id end) == [
               reward.member.id
             ]

      assert Enum.map(result, fn member ->
               Enum.map(member.rewards, fn reward -> reward.id end)
             end) == [
               [reward.id]
             ]
    end

    test "get_member_rewards_by_id/1 returns rewards associated with given member" do
      member = member_fixture()
      reward = RewardsFixtures.reward_fixture(%{member: member})
      result = Members.get_member_rewards_by_id(member.id)
      assert Enum.map(result, fn reward -> reward.id end) == [reward.id]
    end
  end
end

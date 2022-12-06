defmodule EmployeeRewards.MembersTest do
  use EmployeeRewards.DataCase

  alias EmployeeRewards.Members

  describe "members" do
    alias EmployeeRewards.Members.Member

    import EmployeeRewards.MembersFixtures

    @invalid_attrs %{}
    @points_update_attrs %{points: 20}

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

    test "change_member_points/2 returns a member changeset" do
      member = member_fixture()
      assert %Ecto.Changeset{} = Members.change_member_points(member, @points_update_attrs)
    end

    test "get_member_by_credentials/1 with valid data returns a member with given credentials" do
      member = member_fixture()
      assert Members.get_member_by_credentials(member.credentials).id == member.id
    end

    test "reset_members_points/0 updates all members" do
      member = member_fixture()
      assert {1, nil} = Members.reset_members_points()
    end

    test "reset_members_points/0 sets all member points to 50" do
      member = member_fixture()
      Members.reset_members_points()
      assert Members.get_member!(member.id).points == 50
    end
  end
end

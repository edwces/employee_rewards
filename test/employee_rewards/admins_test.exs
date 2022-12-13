defmodule EmployeeRewards.AdminsTest do
  use EmployeeRewards.DataCase

  alias EmployeeRewards.Admins

  describe "admins" do
    alias EmployeeRewards.Admins.Admin

    import EmployeeRewards.AdminsFixtures

    @invalid_attrs %{first_name: nil}

    test "list_admins/0 returns all admins" do
      admin = admin_fixture()
      assert Enum.map(Admins.list_admins(), fn admin -> admin.id end) == [admin.id]
    end

    test "get_admin!/1 returns the admin with given id" do
      admin = admin_fixture()
      assert Admins.get_admin!(admin.id).id == admin.id
    end

    test "get_admin_by_credentials/1 with valid data returns a admin with given credentials" do
      admin = admin_fixture()
      assert Admins.get_admin_by_credentials(admin.credentials).id == admin.id
    end

    test "register_admin/1 with valid data creates a admin" do
      valid_attrs = valid_admin_attributes()

      assert {:ok, %Admin{}} = Admins.register_admin(valid_attrs)
    end

    test "register_admin/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Admins.register_admin(@invalid_attrs)
    end

    test "update_admin/2 with valid data updates the admin" do
      admin = admin_fixture()
      update_attrs = %{}

      assert {:ok, %Admin{}} = Admins.update_admin(admin, update_attrs)
    end

    test "update_admin/2 with invalid data returns error changeset" do
      admin = admin_fixture()
      assert {:error, %Ecto.Changeset{}} = Admins.update_admin(admin, @invalid_attrs)
      assert admin.id == Admins.get_admin!(admin.id).id
    end

    test "delete_admin/1 deletes the admin" do
      admin = admin_fixture()
      assert {:ok, %Admin{}} = Admins.delete_admin(admin)
      assert_raise Ecto.NoResultsError, fn -> Admins.get_admin!(admin.id) end
    end

    test "change_admin/1 returns a admin changeset" do
      admin = admin_fixture()
      assert %Ecto.Changeset{} = Admins.change_admin(admin)
    end
  end
end

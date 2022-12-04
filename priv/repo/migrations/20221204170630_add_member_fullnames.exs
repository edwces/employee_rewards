defmodule EmployeeRewards.Repo.Migrations.AddMemberFullnames do
  use Ecto.Migration

  def change do
    alter table(:members) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
    end
  end
end

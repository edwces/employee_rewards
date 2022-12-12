defmodule EmployeeRewards.Repo.Migrations.CreateRewards do
  use Ecto.Migration

  def change do
    create table(:rewards) do
      add :amount, :integer, null: false
      add :member_id, references(:members)

      timestamps()
    end

    alter table(:members) do
      add :pool, :integer
    end
  end
end

defmodule EmployeeRewards.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members) do
      add :points, :integer, default: 0
      add :credentials_id, references(:credentials)

      timestamps()
    end

    create unique_index(:members, [:credentials_id])
  end
end

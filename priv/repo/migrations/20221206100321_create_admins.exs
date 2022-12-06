defmodule EmployeeRewards.Repo.Migrations.CreateAdmins do
  use Ecto.Migration

  def change do
    create table(:admins) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :credentials_id, references(:credentials)

      timestamps()
    end

    create unique_index(:admins, [:credentials_id])
  end
end

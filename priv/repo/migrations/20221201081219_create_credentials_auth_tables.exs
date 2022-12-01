defmodule EmployeeRewards.Repo.Migrations.CreateCredentialsAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:credentials) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:credentials, [:email])

    create table(:credentials_tokens) do
      add :credentials_id, references(:credentials, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:credentials_tokens, [:credentials_id])
    create unique_index(:credentials_tokens, [:context, :token])
  end
end

defmodule EmployeeRewards.Admins.Admin do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins" do
    field :first_name, :string
    field :last_name, :string
    belongs_to :credentials, EmployeeRewards.Identity.Credentials

    timestamps()
  end

  @doc false
  def register_changeset(admin, attrs) do
    admin
    |> cast(attrs, [:first_name, :last_name])
    |> cast_assoc(:credentials,
      required: true,
      with: &EmployeeRewards.Identity.Credentials.registration_changeset/2
    )
    |> validate_required([:first_name, :last_name])
  end
end

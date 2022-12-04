defmodule EmployeeRewards.Members.Member do
  use Ecto.Schema
  import Ecto.Changeset

  schema "members" do
    field :points, :integer, default: 0
    belongs_to :credentials, EmployeeRewards.Identity.Credentials

    timestamps()
  end

  @doc false
  def register_changeset(member, attrs) do
    member
    |> cast(attrs, [:points])
    |> cast_assoc(:credentials,
      required: true,
      with: &EmployeeRewards.Identity.Credentials.registration_changeset/2
    )
    |> validate_number(:points, greater_than_or_equal_to: 0)
  end

  def points_changeset(member, attrs) do
    member
    |> cast(attrs, [:points])
    |> validate_number(:points, greater_than_or_equal_to: 0)
  end
end

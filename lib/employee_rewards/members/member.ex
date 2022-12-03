defmodule EmployeeRewards.Members.Member do
  use Ecto.Schema
  import Ecto.Changeset

  schema "members" do
    field :points, :integer, default: 0
    belongs_to :credentials, EmployeeRewards.Identity.Credentials

    timestamps()
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:points, :credentials_id])
    |> validate_required([:credentials_id])
    |> validate_number(:points, greater_than_or_equal_to: 0)
    |> unique_constraint([:credentials_id])
  end

  def points_changeset(member, attrs) do
    member
    |> cast(attrs, [:points])
    |> validate_number(:points, greater_than_or_equal_to: 0)
  end
end

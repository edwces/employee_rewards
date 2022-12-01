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
    |> cast(attrs, [])
    |> validate_required([])
  end
end

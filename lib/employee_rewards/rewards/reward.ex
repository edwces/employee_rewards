defmodule EmployeeRewards.Rewards.Reward do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rewards" do
    field :amount, :integer
    belongs_to :member, EmployeeRewards.Members.Member, on_replace: :nilify

    timestamps()
  end

  @doc false
  def changeset(reward, attrs) do
    reward
    |> cast(attrs, [:amount])
    |> put_assoc(:member, attrs.member)
    |> assoc_constraint(:member)
    |> validate_required([:amount])
    |> validate_number(:amount, greater_than: 0)
  end
end

defmodule EmployeeRewards.Rewards.Reward do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rewards" do
    field :amount, :integer
    belongs_to :member, EmployeeRewards.Members.Member

    timestamps()
  end

  @doc false
  def changeset(reward, attrs) do
    reward
    |> cast(attrs, [:amount])
    |> put_assoc(:member, attrs.member, required: true, on_replace: :update)
    |> validate_required([:amount])
    |> validate_number(:amount, greater_than: 0)
  end
end

defmodule EmployeeRewards.Members do
  @moduledoc """
  The Members context.
  """

  import Ecto.Query, warn: false
  alias EmployeeRewards.Rewards
  alias EmployeeRewards.Repo

  alias EmployeeRewards.Members.Member
  alias EmployeeRewards.Identity
  alias EmployeeRewards.Members.MemberEmail

  # REVIEW: Maybe it's better to use just map as a param instead whole credentials struct
  def get_member_by_credentials(%Identity.Credentials{} = credentials) do
    Repo.get_by(Member, credentials_id: credentials.id)
  end

  def get_member_rewards_by_id(id) do
    Repo.all(
      from(entity in Rewards.Reward,
        where: entity.member_id == ^id,
        order_by: [entity.inserted_at]
      )
    )
  end

  def transfer_member_points(%Member{} = from, %Member{} = to, %{points: points}) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :member_from,
      change_member_pool(from, %{pool: from.pool - points})
    )
    |> Ecto.Multi.update(
      :member_to,
      change_member_points(to, %{points: to.points + points})
    )
    |> Ecto.Multi.run(
      :create_reward_entry,
      fn _repo, %{member_to: member} ->
        Rewards.create_reward(%{amount: points, member: member})
      end
    )
    |> Repo.transaction()
  end

  def deliver_member_reward_email(member, amount) do
    member
    |> Repo.preload([:credentials])
    |> MemberEmail.reward(amount)
    |> EmployeeRewards.Mailer.deliver()
  end

  def change_member_points(%Member{} = member, attrs \\ %{}) do
    Member.points_changeset(member, attrs)
  end

  def change_member_pool(%Member{} = member, attrs \\ %{}) do
    Member.pool_changeset(member, attrs)
  end

  def reset_members_points do
    Repo.update_all(Member, set: [pool: 50])
  end

  @doc """
  Returns the list of members.
  
  ## Examples
  
      iex> list_members()
      [%Member{}, ...]
  
  """
  def list_members do
    Repo.all(Member)
  end

  @doc """
  Gets a single member.
  
  Raises `Ecto.NoResultsError` if the Member does not exist.
  
  ## Examples
  
      iex> get_member!(123)
      %Member{}
  
      iex> get_member!(456)
      ** (Ecto.NoResultsError)
  
  """
  def get_member!(id), do: Repo.get!(Member, id)

  @doc """
  Creates a member.
  
  ## Examples
  
      iex> create_member(%{field: value})
      {:ok, %Member{}}
  
      iex> create_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def register_member(attrs \\ %{}) do
    %Member{}
    |> Member.register_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a member.
  
  ## Examples
  
      iex> delete_member(member)
      {:ok, %Member{}}
  
      iex> delete_member(member)
      {:error, %Ecto.Changeset{}}
  
  """
  def delete_member(%Member{} = member) do
    Repo.delete(member)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking member changes.
  
  ## Examples
  
      iex> change_member(member)
      %Ecto.Changeset{data: %Member{}}
  
  """
  def change_member(%Member{} = member, attrs \\ %{}) do
    Member.register_changeset(member, attrs)
  end
end

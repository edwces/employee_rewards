defmodule EmployeeRewards.Members do
  @moduledoc """
  The Members context.
  """

  import Ecto.Query, warn: false
  alias EmployeeRewards.Repo

  alias EmployeeRewards.Members.Member
  alias EmployeeRewards.Identity

  # REVIEW: Maybe it's better to use just map as a param instead whole credentials struct
  def get_member_by_credentials(%Identity.Credentials{} = credentials) do
    Repo.get_by!(Member, credentials_id: credentials.id)
  end

  def transfer_member_points(%Member{} = from, %Member{} = to, %{points: points}) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :member_from,
      change_member_points(from, %{points: from.points - points})
    )
    |> Ecto.Multi.update(
      :member_to,
      change_member_points(to, %{points: to.points + points})
    )
    |> Repo.transaction()
  end

  def change_member_points(%Member{} = member, attrs \\ %{}) do
    Member.points_changeset(member, attrs)
  end

  def reset_members_points do
    Repo.update_all(Member, set: [points: 50])
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
  def create_member(attrs \\ %{}) do
    %Member{}
    |> Member.changeset(attrs)
    |> Repo.insert()
  end

  # REVIEW: maybe try not using raw foreign keys for changeset
  # HACK: we return credentials as they are needed in other controller
  # and we are not preloading it in member
  def register_member(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:credentials, fn _repo, _attrs -> Identity.register_credentials(attrs) end)
    |> Ecto.Multi.run(:member, fn _repo, %{credentials: credentials} ->
      create_member(%{credentials_id: credentials.id})
    end)
    |> Repo.transaction()
  end

  @doc """
  Updates a member.

  ## Examples

      iex> update_member(member, %{field: new_value})
      {:ok, %Member{}}

      iex> update_member(member, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_member(%Member{} = member, attrs) do
    member
    |> Member.changeset(attrs)
    |> Repo.update()
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
    Member.changeset(member, attrs)
  end
end

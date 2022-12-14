defmodule EmployeeRewardsWeb.RewardController do
  use EmployeeRewardsWeb, :controller

  alias EmployeeRewards.Members
  alias EmployeeRewards.Rewards
  alias EmployeeRewards.Rewards.Reward

  def index(conn, _params) do
    rewards = Rewards.list_rewards()
    render(conn, "index.html", rewards: rewards)
  end

  def new(conn, _params) do
    changeset = Rewards.change_reward(%Reward{}, %{member: nil})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"reward" => reward_params}) do
    member = Members.get_member!(reward_params["member_id"])

    case Rewards.create_reward(%{member: member, amount: reward_params["amount"]}) do
      {:ok, reward} ->
        conn
        |> put_flash(:info, "Reward created successfully.")
        |> redirect(to: Routes.reward_path(conn, :show, reward))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    reward = Rewards.get_reward!(id)
    render(conn, "show.html", reward: reward)
  end

  def edit(conn, %{"id" => id}) do
    reward = Rewards.get_reward!(id)
    changeset = Rewards.change_reward(reward)
    render(conn, "edit.html", reward: reward, changeset: changeset)
  end

  def update(conn, %{"id" => id, "reward" => reward_params}) do
    reward = Rewards.get_reward!(id)
    member = Members.get_member!(reward_params["member_id"])

    case Rewards.update_reward(reward, %{member: member, amount: reward_params["amount"]}) do
      {:ok, reward} ->
        conn
        |> put_flash(:info, "Reward updated successfully.")
        |> redirect(to: Routes.reward_path(conn, :show, reward))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", reward: reward, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    reward = Rewards.get_reward!(id)
    {:ok, _reward} = Rewards.delete_reward(reward)

    conn
    |> put_flash(:info, "Reward deleted successfully.")
    |> redirect(to: Routes.reward_path(conn, :index))
  end
end

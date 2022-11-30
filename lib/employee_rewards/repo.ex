defmodule EmployeeRewards.Repo do
  use Ecto.Repo,
    otp_app: :employee_rewards,
    adapter: Ecto.Adapters.Postgres
end

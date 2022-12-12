defmodule EmployeeRewards.Members.MemberEmail do
  import Swoosh.Email

  def reward(member, amount) do
    new()
    |> to({member.first_name, member.credentials.email})
    |> from({"Employee Rewards App", "rewards@gmail.com"})
    |> html_body(
      "<h1>Hello #{member.first_name}</h1><p>You have been granted <bold>#{amount}</bold> points!</p>"
    )
  end
end

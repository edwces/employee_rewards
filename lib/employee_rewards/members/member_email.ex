defmodule EmployeeRewards.Members.MemberEmail do
  import Swoosh.Email

  def reward(member, amount) do
    new()
    |> to(member.credentials.email)
    |> subject("New Points")
    |> from(System.get_env("SENDER_EMAIL"))
    |> html_body(
      "<h1>Hello #{member.first_name}</h1><p>You have been granted <bold>#{amount}</bold> points!</p>"
    )
  end
end

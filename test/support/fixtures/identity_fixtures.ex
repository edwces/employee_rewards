defmodule EmployeeRewards.IdentityFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EmployeeRewards.Identity` context.
  """

  def unique_credentials_email, do: "credentials#{System.unique_integer()}@example.com"
  def valid_credentials_password, do: "hello world!"

  def valid_credentials_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_credentials_email(),
      password: valid_credentials_password()
    })
  end

  def credentials_fixture(attrs \\ %{}) do
    {:ok, credentials} =
      attrs
      |> valid_credentials_attributes()
      |> EmployeeRewards.Identity.register_credentials()

    credentials
  end

  def extract_credentials_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end

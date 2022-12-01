defmodule EmployeeRewardsWeb.CredentialsSessionController do
  use EmployeeRewardsWeb, :controller

  alias EmployeeRewards.Identity
  alias EmployeeRewardsWeb.CredentialsAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"credentials" => credentials_params}) do
    %{"email" => email, "password" => password} = credentials_params

    if credentials = Identity.get_credentials_by_email_and_password(email, password) do
      CredentialsAuth.log_in_credentials(conn, credentials, credentials_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> CredentialsAuth.log_out_credentials()
  end
end

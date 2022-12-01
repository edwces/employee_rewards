defmodule EmployeeRewardsWeb.CredentialsRegistrationController do
  use EmployeeRewardsWeb, :controller

  alias EmployeeRewards.Identity
  alias EmployeeRewards.Identity.Credentials
  alias EmployeeRewardsWeb.CredentialsAuth

  def new(conn, _params) do
    changeset = Identity.change_credentials_registration(%Credentials{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"credentials" => credentials_params}) do
    case Identity.register_credentials(credentials_params) do
      {:ok, credentials} ->
        {:ok, _} =
          Identity.deliver_credentials_confirmation_instructions(
            credentials,
            &Routes.credentials_confirmation_url(conn, :edit, &1)
          )

        conn
        |> put_flash(:info, "Credentials created successfully.")
        |> CredentialsAuth.log_in_credentials(credentials)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end

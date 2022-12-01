defmodule EmployeeRewardsWeb.CredentialsRegistrationController do
  use EmployeeRewardsWeb, :controller

  alias EmployeeRewards.Identity
  alias EmployeeRewards.Identity.Credentials
  alias EmployeeRewards.Members
  alias EmployeeRewardsWeb.CredentialsAuth

  def new(conn, _params) do
    changeset = Identity.change_credentials_registration(%Credentials{})
    render(conn, "new.html", changeset: changeset)
  end

  # REVIEW: Should Members and Identity Contexts functions be mixed together.
  # Should Identity.deliver_credentials_confirmation_instructions be moved
  # to register member function OR maybe remove creating credentials in Members module
  def create(conn, %{"credentials" => credentials_params}) do
    case Members.register_member(credentials_params) do
      {:ok, _member, credentials} ->
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

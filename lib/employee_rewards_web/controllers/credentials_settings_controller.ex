defmodule EmployeeRewardsWeb.CredentialsSettingsController do
  use EmployeeRewardsWeb, :controller

  alias EmployeeRewards.Identity
  alias EmployeeRewardsWeb.CredentialsAuth

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "credentials" => credentials_params} = params
    credentials = conn.assigns.current_credentials

    case Identity.apply_credentials_email(credentials, password, credentials_params) do
      {:ok, applied_credentials} ->
        Identity.deliver_update_email_instructions(
          applied_credentials,
          credentials.email,
          &Routes.credentials_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.credentials_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "credentials" => credentials_params} = params
    credentials = conn.assigns.current_credentials

    case Identity.update_credentials_password(credentials, password, credentials_params) do
      {:ok, credentials} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:credentials_return_to, Routes.credentials_settings_path(conn, :edit))
        |> CredentialsAuth.log_in_credentials(credentials)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Identity.update_credentials_email(conn.assigns.current_credentials, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.credentials_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.credentials_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    credentials = conn.assigns.current_credentials

    conn
    |> assign(:email_changeset, Identity.change_credentials_email(credentials))
    |> assign(:password_changeset, Identity.change_credentials_password(credentials))
  end
end

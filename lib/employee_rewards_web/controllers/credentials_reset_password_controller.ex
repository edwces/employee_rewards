defmodule EmployeeRewardsWeb.CredentialsResetPasswordController do
  use EmployeeRewardsWeb, :controller

  alias EmployeeRewards.Identity

  plug :get_credentials_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"credentials" => %{"email" => email}}) do
    if credentials = Identity.get_credentials_by_email(email) do
      Identity.deliver_credentials_reset_password_instructions(
        credentials,
        &Routes.credentials_reset_password_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: Identity.change_credentials_password(conn.assigns.credentials))
  end

  # Do not log in the credentials after reset password to avoid a
  # leaked token giving the credentials access to the account.
  def update(conn, %{"credentials" => credentials_params}) do
    case Identity.reset_credentials_password(conn.assigns.credentials, credentials_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.credentials_session_path(conn, :new))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp get_credentials_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if credentials = Identity.get_credentials_by_reset_password_token(token) do
      conn |> assign(:credentials, credentials) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end

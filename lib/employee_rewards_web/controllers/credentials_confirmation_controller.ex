defmodule EmployeeRewardsWeb.CredentialsConfirmationController do
  use EmployeeRewardsWeb, :controller

  alias EmployeeRewards.Identity

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"credentials" => %{"email" => email}}) do
    if credentials = Identity.get_credentials_by_email(email) do
      Identity.deliver_credentials_confirmation_instructions(
        credentials,
        &Routes.credentials_confirmation_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  # Do not log in the credentials after confirmation to avoid a
  # leaked token giving the credentials access to the account.
  def update(conn, %{"token" => token}) do
    case Identity.confirm_credentials(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Credentials confirmed successfully.")
        |> redirect(to: "/")

      :error ->
        # If there is a current credentials and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the credentials themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_credentials: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Credentials confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end

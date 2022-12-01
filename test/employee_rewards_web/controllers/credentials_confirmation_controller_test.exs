defmodule EmployeeRewardsWeb.CredentialsConfirmationControllerTest do
  use EmployeeRewardsWeb.ConnCase, async: true

  alias EmployeeRewards.Identity
  alias EmployeeRewards.Repo
  import EmployeeRewards.IdentityFixtures

  setup do
    %{credentials: credentials_fixture()}
  end

  describe "GET /credentials/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.credentials_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /credentials/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, credentials: credentials} do
      conn =
        post(conn, Routes.credentials_confirmation_path(conn, :create), %{
          "credentials" => %{"email" => credentials.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Identity.CredentialsToken, credentials_id: credentials.id).context == "confirm"
    end

    test "does not send confirmation token if Credentials is confirmed", %{conn: conn, credentials: credentials} do
      Repo.update!(Identity.Credentials.confirm_changeset(credentials))

      conn =
        post(conn, Routes.credentials_confirmation_path(conn, :create), %{
          "credentials" => %{"email" => credentials.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Identity.CredentialsToken, credentials_id: credentials.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.credentials_confirmation_path(conn, :create), %{
          "credentials" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Identity.CredentialsToken) == []
    end
  end

  describe "GET /credentials/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.credentials_confirmation_path(conn, :edit, "some-token"))
      response = html_response(conn, 200)
      assert response =~ "<h1>Confirm account</h1>"

      form_action = Routes.credentials_confirmation_path(conn, :update, "some-token")
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "POST /credentials/confirm/:token" do
    test "confirms the given token once", %{conn: conn, credentials: credentials} do
      token =
        extract_credentials_token(fn url ->
          Identity.deliver_credentials_confirmation_instructions(credentials, url)
        end)

      conn = post(conn, Routes.credentials_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Credentials confirmed successfully"
      assert Identity.get_credentials!(credentials.id).confirmed_at
      refute get_session(conn, :credentials_token)
      assert Repo.all(Identity.CredentialsToken) == []

      # When not logged in
      conn = post(conn, Routes.credentials_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Credentials confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_credentials(credentials)
        |> post(Routes.credentials_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, credentials: credentials} do
      conn = post(conn, Routes.credentials_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Credentials confirmation link is invalid or it has expired"
      refute Identity.get_credentials!(credentials.id).confirmed_at
    end
  end
end

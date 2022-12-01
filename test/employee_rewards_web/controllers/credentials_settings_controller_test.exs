defmodule EmployeeRewardsWeb.CredentialsSettingsControllerTest do
  use EmployeeRewardsWeb.ConnCase, async: true

  alias EmployeeRewards.Identity
  import EmployeeRewards.IdentityFixtures

  setup :register_and_log_in_credentials

  describe "GET /credentials/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.credentials_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if credentials is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.credentials_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.credentials_session_path(conn, :new)
    end
  end

  describe "PUT /credentials/settings (change password form)" do
    test "updates the credentials password and resets tokens", %{conn: conn, credentials: credentials} do
      new_password_conn =
        put(conn, Routes.credentials_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_credentials_password(),
          "credentials" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.credentials_settings_path(conn, :edit)
      assert get_session(new_password_conn, :credentials_token) != get_session(conn, :credentials_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Identity.get_credentials_by_email_and_password(credentials.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.credentials_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "credentials" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :credentials_token) == get_session(conn, :credentials_token)
    end
  end

  describe "PUT /credentials/settings (change email form)" do
    @tag :capture_log
    test "updates the credentials email", %{conn: conn, credentials: credentials} do
      conn =
        put(conn, Routes.credentials_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_credentials_password(),
          "credentials" => %{"email" => unique_credentials_email()}
        })

      assert redirected_to(conn) == Routes.credentials_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert Identity.get_credentials_by_email(credentials.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.credentials_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "credentials" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /credentials/settings/confirm_email/:token" do
    setup %{credentials: credentials} do
      email = unique_credentials_email()

      token =
        extract_credentials_token(fn url ->
          Identity.deliver_update_email_instructions(%{credentials | email: email}, credentials.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the credentials email once", %{conn: conn, credentials: credentials, token: token, email: email} do
      conn = get(conn, Routes.credentials_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.credentials_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Identity.get_credentials_by_email(credentials.email)
      assert Identity.get_credentials_by_email(email)

      conn = get(conn, Routes.credentials_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.credentials_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, credentials: credentials} do
      conn = get(conn, Routes.credentials_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.credentials_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Identity.get_credentials_by_email(credentials.email)
    end

    test "redirects if credentials is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.credentials_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.credentials_session_path(conn, :new)
    end
  end
end

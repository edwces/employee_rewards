defmodule EmployeeRewardsWeb.CredentialsSessionControllerTest do
  use EmployeeRewardsWeb.ConnCase, async: true

  import EmployeeRewards.IdentityFixtures

  setup do
    %{credentials: credentials_fixture()}
  end

  describe "GET /credentials/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.credentials_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Register</a>"
      assert response =~ "Forgot your password?</a>"
    end

    test "redirects if already logged in", %{conn: conn, credentials: credentials} do
      conn = conn |> log_in_credentials(credentials) |> get(Routes.credentials_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /credentials/log_in" do
    test "logs the credentials in", %{conn: conn, credentials: credentials} do
      conn =
        post(conn, Routes.credentials_session_path(conn, :create), %{
          "credentials" => %{"email" => credentials.email, "password" => valid_credentials_password()}
        })

      assert get_session(conn, :credentials_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ credentials.email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "logs the credentials in with remember me", %{conn: conn, credentials: credentials} do
      conn =
        post(conn, Routes.credentials_session_path(conn, :create), %{
          "credentials" => %{
            "email" => credentials.email,
            "password" => valid_credentials_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_employee_rewards_web_credentials_remember_me"]
      assert redirected_to(conn) == "/"
    end

    test "logs the credentials in with return to", %{conn: conn, credentials: credentials} do
      conn =
        conn
        |> init_test_session(credentials_return_to: "/foo/bar")
        |> post(Routes.credentials_session_path(conn, :create), %{
          "credentials" => %{
            "email" => credentials.email,
            "password" => valid_credentials_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, credentials: credentials} do
      conn =
        post(conn, Routes.credentials_session_path(conn, :create), %{
          "credentials" => %{"email" => credentials.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /credentials/log_out" do
    test "logs the credentials out", %{conn: conn, credentials: credentials} do
      conn = conn |> log_in_credentials(credentials) |> delete(Routes.credentials_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :credentials_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the credentials is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.credentials_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :credentials_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end

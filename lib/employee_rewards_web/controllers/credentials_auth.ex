defmodule EmployeeRewardsWeb.CredentialsAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias EmployeeRewards.Members
  alias EmployeeRewards.Admins
  alias EmployeeRewards.Identity
  alias EmployeeRewardsWeb.Router.Helpers, as: Routes

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in CredentialsToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_employee_rewards_web_credentials_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the credentials in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_credentials(conn, credentials, params \\ %{}) do
    token = Identity.generate_credentials_session_token(credentials)
    credentials_return_to = get_session(conn, :credentials_return_to)

    conn
    |> renew_session()
    |> put_session(:credentials_token, token)
    |> put_session(:live_socket_id, "credentials_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: credentials_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the credentials out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_credentials(conn) do
    credentials_token = get_session(conn, :credentials_token)
    credentials_token && Identity.delete_session_token(credentials_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      EmployeeRewardsWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the credentials by looking into the session
  and remember me token.
  """
  # REVIEW: Should probably be in it's own standalone module
  # and abstract and put credentials as association.
  # Maybe store extra profile info in just one assign and add
  # is_admin as boolean value for better templating logic
  def fetch_current_auth(conn, _opts) do
    {credentials_token, conn} = ensure_credentials_token(conn)

    credentials =
      credentials_token && Identity.get_credentials_by_session_token(credentials_token)

    member = credentials && Members.get_member_by_credentials(credentials)
    admin = credentials && Admins.get_admin_by_credentials(credentials)

    conn
    |> assign(:current_credentials, credentials)
    |> assign(:current_member, member)
    |> assign(:current_admin, admin)
  end

  defp ensure_credentials_token(conn) do
    if credentials_token = get_session(conn, :credentials_token) do
      {credentials_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if credentials_token = conn.cookies[@remember_me_cookie] do
        {credentials_token, put_session(conn, :credentials_token, credentials_token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Used for routes that require the credentials to not be authenticated.
  """
  def redirect_if_credentials_is_authenticated(conn, _opts) do
    if conn.assigns[:current_credentials] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the credentials to be authenticated.

  If you want to enforce the credentials email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_credentials(conn, _opts) do
    if conn.assigns[:current_credentials] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: Routes.credentials_session_path(conn, :new))
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :credentials_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/"
end

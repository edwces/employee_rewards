defmodule EmployeeRewardsWeb.Router do
  use EmployeeRewardsWeb, :router

  import EmployeeRewardsWeb.CredentialsAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {EmployeeRewardsWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_credentials
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EmployeeRewardsWeb do
    pipe_through :browser

    get "/", MemberController, :index
    get "/members/:id/grant", MemberController, :grant
  end

  # Other scopes may use custom stacks.
  # scope "/api", EmployeeRewardsWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: EmployeeRewardsWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", EmployeeRewardsWeb do
    pipe_through [:browser, :redirect_if_credentials_is_authenticated]

    get "/credentials/register", CredentialsRegistrationController, :new
    post "/credentials/register", CredentialsRegistrationController, :create
    get "/credentials/log_in", CredentialsSessionController, :new
    post "/credentials/log_in", CredentialsSessionController, :create
    get "/credentials/reset_password", CredentialsResetPasswordController, :new
    post "/credentials/reset_password", CredentialsResetPasswordController, :create
    get "/credentials/reset_password/:token", CredentialsResetPasswordController, :edit
    put "/credentials/reset_password/:token", CredentialsResetPasswordController, :update
  end

  scope "/", EmployeeRewardsWeb do
    pipe_through [:browser, :require_authenticated_credentials]

    get "/credentials/settings", CredentialsSettingsController, :edit
    put "/credentials/settings", CredentialsSettingsController, :update

    get "/credentials/settings/confirm_email/:token",
        CredentialsSettingsController,
        :confirm_email
  end

  scope "/", EmployeeRewardsWeb do
    pipe_through [:browser]

    delete "/credentials/log_out", CredentialsSessionController, :delete
    get "/credentials/confirm", CredentialsConfirmationController, :new
    post "/credentials/confirm", CredentialsConfirmationController, :create
    get "/credentials/confirm/:token", CredentialsConfirmationController, :edit
    post "/credentials/confirm/:token", CredentialsConfirmationController, :update
  end
end

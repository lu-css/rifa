defmodule RifaWeb.Router do
  use RifaWeb, :router

  import RifaWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {RifaWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :adm do
    plug :require_adm
  end

  scope "/", RifaWeb do
    pipe_through([:api])
    
    get "/rifas/:id/makesorteio", RifaPartyController, :makesorteio
  end

  scope "/", RifaWeb do
    pipe_through([:browser, :require_authenticated_user, :adm])

    resources("/rifas", RifaPartyController, except: [:index, :show])

    get "/rifas/:id/buynumber", RifaPartyController, :buy_a_number
    get "/rifas/:id/show_admin", RifaPartyController, :show_admin
    get "/rifas/adm", RifaPartyController, :view_admin
    get "/rifas/:id/removenumber", RifaPartyController, :remove_number

    post "/users/add_admin", UserRegistrationController, :add_admin
    get "/rifas/:id/stats", RifaPartyController, :number_stats

    get "/rifas/:id/sorteio", RifaPartyController, :sorteio

    delete "/rifas/:id/deleteNumber", RifaPartyController, :delete_number
  end

  scope "/", RifaWeb do
    pipe_through(:browser)

    get "/", RifaPartyController, :index

    resources("/rifas", RifaPartyController, only: [:index, :show])
    post "rifas/buy_rifa", RifaPartyController, :buy_rifa
  end

  # Other scopes may use custom stacks.
  # scope "/api", RifaWeb do
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
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: RifaWeb.Telemetry)
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through(:browser)

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", RifaWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", RifaWeb do
    pipe_through([:browser, :require_authenticated_user])

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", RifaWeb do
    pipe_through([:browser])

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end
end

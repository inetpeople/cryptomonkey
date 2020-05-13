defmodule CryptoMonkeyWeb.Router do
  use CryptoMonkeyWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {CryptoMonkeyWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :webhook do
    plug :accepts, ["html", "json"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CryptoMonkeyWeb do
    pipe_through :browser
    # , session: [:user_id]
    live "/ticker", TickerLive
    # , session: [:user_id]
    live "/signals", SignalLive
    # , session: [:user_id]
    live "/makerdao", MakerDaoLive

    live "/tests", TestLive.Index, :index
    live "/tests/new", TestLive.Index, :new
    live "/tests/:id/edit", TestLive.Index, :edit

    live "/tests/:id", TestLive.Show, :show
    live "/tests/:id/show/edit", TestLive.Show, :edit

    # get "/", PageController, :index
    live "/", PageLive, :index
  end

  #### API ####
  # scope "/api", CryptoMonkeyWeb do
  #   pipe_through :api
  # end

  #### Webhook ####
  scope "/webhook", CryptoMonkeyWeb do
    pipe_through :webhook

    post "/", WebhookController, :hook
  end

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
      live_dashboard "/dashboard", metrics: CryptoMonkeyWeb.Telemetry
    end
  end
end

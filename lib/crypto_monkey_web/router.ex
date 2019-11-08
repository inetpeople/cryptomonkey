defmodule CryptoMonkeyWeb.Router do
  use CryptoMonkeyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
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
    live "/ticker", TickerLive, session: [:user_id]
    get "/", PageController, :index
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
end

defmodule CryptoMonkeyWeb.PageController do
  use CryptoMonkeyWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

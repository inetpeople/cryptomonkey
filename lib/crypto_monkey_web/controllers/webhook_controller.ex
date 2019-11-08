defmodule CryptoMonkeyWeb.WebhookController do
  use CryptoMonkeyWeb, :controller
  require Logger
  alias CryptoMonkey.Boundary.Signal

  def hook(conn, params) do
    IO.inspect(params)
    # IO.inspect(conn)

    case %{} == params do
      true ->
        process_signal(conn)

      false ->
        process_params(params)
    end

    json(conn, %{ok: true})
  end

  defp process_params(params) do
    Signal.Server.new_signal(Signal.Server, params)
    Logger.info("New Signal in Parameters")
  end

  defp process_signal(conn) do
    signal = Plug.Conn.read_body(conn, length: 1_000_000)

    case signal do
      {:ok, signal, conn} ->
        Signal.Server.new_signal(Signal.Server, signal)
        Logger.info("New Signal: #{signal}")

        json(conn, %{ok: true})

      {:error, reason} ->
        json(conn, %{error: reason})
    end
  end
end

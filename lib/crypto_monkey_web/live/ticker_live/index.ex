defmodule CryptoMonkeyWeb.TickerLive.Index do
  use CryptoMonkeyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(CryptoMonkey.PubSub, "krakenx_futures")
    end

    socket =
      assign(socket,
        available_tickers: available_tickers(),
        query: "",
        results: %{}
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  @impl true
  def handle_info(_debug, socket) do
    # IO.inspect(debug)
    {:noreply, socket}
  end

  defp search(query) do
    for ticker <- available_tickers
        String.starts_with?(ticker, query),
        into: %{},
        do: {app, vsn}
  end

  defp available_tickers do
    ["PI_ETHUSD", "PI_XBTUSD"]
  end
end

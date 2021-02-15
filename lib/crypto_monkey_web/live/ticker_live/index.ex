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
        results: [],
        loading: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    result = suggest(query)
    socket = assign(socket, results: result)

    {:noreply, socket}
  end

  def handle_event("search", %{"q" => ticker}, socket) do
    send(self(), {:run_search, ticker})

    socket =
      assign(socket,
        loading: true,
        results: [],
        ticker: ticker
      )

    {:noreply, socket}
  end

  def handle_info("run_search", %{"q" => query}, socket) do
    case search(query) do
      [] ->
        socket =
          socket
          |> put_flash(:info, "No results matching \"#{query}\"")
          |> assign(results: [], loading: false)

        {:noreply, socket}

      result ->
        socket =
          socket
          |> clear_flash()
          |> assign(results: result, loading: false)

        {:noreply, socket}
    end

    # %{^query => vsn} ->
    #   {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

    # _ ->
    #   {:noreply,
    #    socket
    #    |> put_flash(:error, "No dependencies found matching \"#{query}\"")
    #    |> assign(results: %{}, query: query)}
  end

  @impl true
  def handle_info(_debug, socket) do
    # IO.inspect(debug)
    {:noreply, socket}
  end

  defp search(query) do
  end

  defp available_tickers do
    ["PI_ETHUSD", "PI_XBTUSD"]
  end

  def suggest(""), do: []

  def suggest(prefix) do
    Enum.filter(available_tickers(), &has_prefix?(&1, prefix))
  end

  defp has_prefix?(city, prefix) do
    String.contains?(String.downcase(city), String.downcase(prefix))
  end
end

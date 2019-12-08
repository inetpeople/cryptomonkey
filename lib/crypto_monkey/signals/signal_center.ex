defmodule CryptoMonkey.Signals.EventCenter do
  use GenServer
  alias Phoenix.PubSub
  alias CryptoMonkey.Repo
  alias CryptoMonkey.Signals.Signal

  @name __MODULE__

  def new do
    %{
      db_signals: [],
      active_signals: [],
      confirmed_signals: [],
      published_signals: []
    }
  end

  def start_link(opts \\ []) when is_list(opts) do
    state = :ok
    GenServer.start_link(__MODULE__, state, opts ++ [name: @name])
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  def flush(pid) do
    GenServer.cast(pid, :flush)
  end

  ### server
  # GenServer callbacks
  @impl true

  def init(:ok) do
    new_state = new()
    db_signals = Repo.all(Signals)
    active_signals = active_signals(db_signals)
    confirmed_signals = confirmed_signals(db_signals)
    closed_signals = closed_signals(db_signals)

    state = %{
      new_state
      | db_signals: db_signals,
        active_signals: active_signals,
        confirmed_signals: confirmed_signals,
        closed_signals: closed_signals
    }

    # send(self(), :get_all_signals)
    {:ok, state}
  end

  defp active_signals(signals) when is_list(signals),
    do: signals |> Enum.filter(fn x -> x.closed_at == nil end)

  defp confirmed_signals(signals) when is_list(signals),
    do: signals |> Enum.filter(fn x -> x.confirmed_at != nil end)

  defp closed_signals(signals) when is_list(signals),
    do: signals |> Enum.filter(fn x -> x.closed_at != nil end)

  @impl true
  def handle_cast(:load_all_signals, state) do
    signals = Repo.all(Signals)
    {:noreply, [signals | state]}
  end

  def handle_cast({:active_signals, _signals}, state) do
    {:noreply, state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_cast(:flush, _state) do
    {:noreply, %{}}
  end
end

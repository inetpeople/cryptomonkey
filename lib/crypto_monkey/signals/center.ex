defmodule CryptoMonkey.Signals.Center do
  use GenServer
  alias Phoenix.PubSub
  alias CryptoMonkey.Repo
  alias CryptoMonkey.Signals.Signal
  import Ecto.Query

  @name __MODULE__
  @topic "signals"

  defstruct signals: []

  def new do
    %__MODULE__{}
  end

  def start_link(opts \\ []) when is_list(opts) do
    state = :ok
    GenServer.start_link(__MODULE__, state, opts ++ [name: @name])
  end

  def list_signals(pid) do
    GenServer.call(pid, :list_signals)
  end

  @spec stop(atom | pid | {atom, any} | {:via, atom, any}) :: :ok
  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  @spec flush(atom | pid | {atom, any} | {:via, atom, any}) :: :ok
  def flush(pid) do
    GenServer.cast(pid, :flush)
  end

  def update_signal(pid) do
    GenServer.cast(pid, :update_signal)
  end

  ### server
  # GenServer callbacks

  @impl true
  @spec init(:ok) :: {:ok, CryptoMonkey.Signals.EventCenter.t()}
  def init(:ok) do
    db_signals = list_signals()

    # signals = %{
    #   active_signals: active_signals(db_signals),
    #   confirmed_signals: confirmed_signals(db_signals),
    #   closed_signals: closed_signals(db_signals)
    # }

    {:ok, %{signals: db_signals}}
  end

  @impl true
  def handle_call(:list_signals, _from, state) do
    CryptoMonkeyWeb.Endpoint.broadcast(@topic, "list_signals", state)
    {:reply, state, state}
  end

  def handle_cast({:update_signals, signal}, state) do
    _signals = Map.fetch(state, signal.id)

    {:noprely, state}
  end

  def handle_cast(:list_signals, state) do
    CryptoMonkeyWeb.Endpoint.broadcast(@topic, "list_signals", state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:signal_closed, _signals}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast(:flush, _state) do
    {:noreply, %{}}
  end

  #####
  ### private
  #####
  def list_signals(), do: Repo.all(Signal)

  @spec active_signals([Signal.t()]) :: [Signal.t()]
  defp active_signals(signals) when is_list(signals),
    do: signals |> Enum.filter(fn x -> x.closed_at == nil end)

  @spec confirmed_signals([Signal.t()]) :: [Signal.t()]
  defp confirmed_signals(signals) when is_list(signals),
    do: signals |> Enum.filter(fn x -> x.confirmed_at != nil end)

  @spec closed_signals(Signal.t()) :: [Signal.t()]
  defp closed_signals(signals) when is_list(signals),
    do: signals |> Enum.filter(fn x -> x.closed_at != nil end)
end

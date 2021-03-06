defmodule CryptoMonkey.Boundary.Signal.Server do
  use GenServer
  import Logger, only: [info: 1]
  alias CryptoMonkey.Boundary.Signal.{Item}
  @name __MODULE__

  def start_link(signal) when is_list(signal) do
    GenServer.start_link(__MODULE__, signal, name: @name)
  end

  def new_signal(pid, signal) do
    GenServer.cast(pid, {:new_signal, signal})
    info("New Signal")
  end

  def list_signal(pid) do
    GenServer.call(pid, :list_signal)
  end

  # Callbacks
  @impl true
  def init(signal) do
    {:ok, signal}
  end

  @impl true
  def handle_cast({:new_signal, signal}, state) do
    {:ok, signal} = Item.new(signal)

    {:noreply, [signal | state]}
  end

  @impl true
  def handle_call(:list_signal, _from, state) do
    {:reply, state, state}
  end
end

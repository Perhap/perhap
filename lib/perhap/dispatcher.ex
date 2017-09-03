defmodule Perhap.Dispatcher do
  use GenServer
  require Logger

  @spec dispatch(term(), Perhap.Event.t, any()) :: { :noreply, any() }
  def dispatch(child, event, _opts) do
    GenServer.cast(child, {:dispatch, event})
  end

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def handle_call(request, from, state) do
    super(request, from, state)
  end

  def handle_cast({:dispatch, _event, _opts}, state) do
    {:noreply, state}
  end

  def handle_cast(request, state) do
    super(request, state)
  end

  def terminate(_, _) do
    Logger.debug("#{__MODULE__}.terminate")
  end
end

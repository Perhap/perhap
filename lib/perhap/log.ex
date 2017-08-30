defmodule Perhap.Log do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def handle_call(request, from, state) do
    super(request, from, state)
  end

  def handle_cast(request, state) do
    IO.inspect request
    {:noreply, state}
  end
end

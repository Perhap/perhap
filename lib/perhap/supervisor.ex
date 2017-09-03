defmodule Perhap.Supervisor do
  use Supervisor

  def start_link(args) do
    IO.inspect({__MODULE__, args, self()})
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init([Perhap.Dispatcher], strategy: :one_for_one)
  end

  def stop() do
    Supervisor.stop(__MODULE__)
  end

  def register({module, name}) do
    Supervisor.start_child(__MODULE__, apply(module, :child_spec, [name]))
  end

end

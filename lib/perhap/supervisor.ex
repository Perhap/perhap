defmodule Perhap.Supervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init([], strategy: :one_for_one)
  end

  def register({module, name}) do
    {:ok, _pid} = Supervisor.start_child(__MODULE__, apply(module, :child_spec, [name]))
  end

end

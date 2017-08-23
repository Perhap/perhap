defmodule Perhap.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_arg) do
    Supervisor.init([], strategy: :one_for_one)
  end

  def register_domain_service({module, args}, entity_id) do
    {:ok, _pid} = Supervisor.start_child(__MODULE__,
                                         Supervisor.child_spec( module, id: {module, entity_id}))
  end
end

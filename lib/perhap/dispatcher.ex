defmodule Perhap.Dispatcher do
  use GenServer, restart: :temporary
  require Logger

  @spec dispatch(term(), term(), Perhap.Event.t, any()) :: { :noreply, any() }
  def dispatch(dispatcher, child, event, opts) do
    GenServer.cast({:via, :swarm, dispatcher}, {:dispatch, child, event, opts})
  end

  @spec start_service(term()) :: {:ok, pid()}
  def start_service(name) do
    {:ok, pid} = Swarm.register_name(name, Supervisor, :start_child, [{:via, :swarm, :perhap}, child_spec(name)])
    Swarm.join(:perhap, pid)
    {:ok, pid}
  end

  def ensure_started(name) do
    case Swarm.whereis_name(name) do
      :undefined -> start_service(name)
      pid -> {:ok, pid}
    end
  end

  def start_link(name) do
    GenServer.start_link(__MODULE__, [name])
  end

  def init([name]) do
    Process.flag(:trap_exit, true)
    {:ok, name}
  end

  def child_spec(name) do
    %{ super(name) | id: name }
  end

  def handle_call({:swarm, :begin_handoff}, _from, state) do
    {:reply, {:resume, state}, state}
  end
  def handle_call(req, from, state) do
    super(req, from, state)
  end

  def handle_cast({:dispatch, {module, _name} = child, event, _opts}, state) do
    apply(module, :ensure_started, [child])
    apply(module, :reduce, [child, event])
    {:noreply, state}
  end
  def handle_cast({:swarm, :end_handoff, state}, _) do
    {:noreply, state}
  end
  def handle_cast({:swarm, :resolve_conflict, _state}, state) do
    # ignore
    {:noreply, state}
  end
  def handle_cast(request, state) do
    super(request, state)
  end

  def handle_info({:swarm, :die}, state) do
    {:stop, :shutdown, state}
  end

  def terminate(_, _) do
    Logger.debug("#{__MODULE__}.terminate")
  end
end

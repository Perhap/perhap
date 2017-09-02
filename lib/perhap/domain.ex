defmodule Perhap.Domain do
  @callback reducer(atom(), term(), Perhap.Event.t) :: { term(), list(Perhap.Event.t)}

  defmacro __using__(_) do
    quote location: :keep do
      require Logger
      use GenServer, restart: :temporary

      @behaviour Perhap.Domain
      @initial_state nil

      @before_compile unquote(__MODULE__)

      # Interface

      #@spec reduce(service_id: Perhap.Event.UUIDv4.t | module(),
      #             event: list(Perhap.Event.t) | Perhap.Event.t) :: :ok
      def reduce(service_id, event) when not is_list(event), do: reduce(service_id, Enum.wrap(event))
      def reduce(service_id, events) do
        GenServer.cast({:via, :swarm, service_id}, {:reduce, events})
      end

      @spec retrieve(service_id: Perhap.Event.UUIDv4.t | module(), args: map()) :: term()
      def retrieve(service_id, args \\ %{}) do
        {:reply, reply, state} = GenServer.call({:via, :swarm, service_id}, {:retrieve, args})
        reply
      end

      # Overridable functions

      @spec reducer(atom(), term(), Perhap.Event.t) :: { term(), list(Perhap.Event.t) }
      # (CompileError) test/support/perhaptest_fixture.exs:17: spec for undefined function reduce/1
      # Arity 1? Nah.
      def reducer(_event_type, model, _event) do
        Logger.error("[perhap] No reducer defined in module #{__MODULE__}.")
        { model, [] }
      end

      #@spec retriever(state: term(), args: map()) :: { :ok, term() } | { :error, String.t }
      # (CompileError) test/support/perhaptest_fixture.exs:17: spec for undefined function retriever/1
      # Arity 1? Nah.
      def retriever(state, _args), do: {:ok, state}

      defoverridable([reducer: 3, retriever: 2])

      # Setup

      def terminate(reason, state) do
        super(reason, state)
      end

      # Callbacks

      def child_spec(arg) do
        %{ super(arg) | id: arg }
      end

      def init(state) do
        Logger.debug("[perhap] #{__MODULE__}.init with initial state #{inspect(state)}")
        Process.flag(:trap_exit, true)
        {:ok, state}
      end

      # Calls and Casts for Perhap
      def handle_call({:retrieve, args}, _from, state) do
        reply = retriever(state, args)
        { :reply, reply, state }
      end

      def handle_cast({:reduce, events}, state) do
        { model, new_events } = Enum.reduce( events,
                                             {state, []},
                                             fn event, { state, _new_events } ->
                                               reducer(event.metadata.type, state, event)
                                             end )
        # todo: publish new events
        {:noreply, model}
      end

      # Calls and Casts for Swarm
      def handle_call({:swarm, :begin_handoff}, _from, state) do
        {:reply, {:resume, state}, state}
      end

      def handle_cast({:swarm, :end_handoff, state}, _) do
        {:noreply, state}
      end

      def handle_cast({:swarm, :resolve_conflict, _state}, state) do
        # ignore
        {:noreply, state}
      end

      def handle_call(req, from, state) do
        super(req, from, state)
      end

      # Unhandled Calls and Casts
      def handle_cast(req, state) do
        IO.inspect(req)
        super(req, state)
      end

      def handle_info({:swarm, :die}, state) do
        {:stop, :shutdown, state}
      end

    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def start_link(name) do
        Logger.debug("[perhap] #{__MODULE__}.start_link with name #{inspect(name)}")
        GenServer.start_link(__MODULE__, @initial_state)
      end
    end
  end

end

defmodule Perhap.Adapters.Eventstore.Memory do
  use Perhap.Adapters.Eventstore
  use Agent

  @type t :: [ events: events, index: indexes ]
  @type events  :: %{ required(Perhap.Event.UUIDv1.t) => Perhap.Event.t }
  @type indexes :: %{ required({atom(), Perhap.Event.UUIDv4.t}) => list(Perhap.Event.UUIDv1.t) }

  defstruct events: %{}, index: %{}

  @spec start_link(opts: any()) ::   {:ok, pid} | :ignore | {:error, {:already_started, pid} | term}
  def start_link(_args) do
    Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)
  end

  @spec put_event(event: Perhap.Event.t) :: :ok | {:error, term}
  def put_event(event) do
    Agent.update( __MODULE__,
                  fn %__MODULE__{events: events, index: index} ->
                    id = event.event_id |> Perhap.Event.uuid_v1_to_time_order
                    events2 = Map.put(events, id, event)
                    index_key = { event.metadata.context, event.metadata.entity_id }
                    index_value = [ id | Map.get(index, index_key, []) ]
                    index2 = Map.put(index, index_key, index_value)
                    %__MODULE__{events: events2, index: index2}
                  end )
    :ok
  end

  @spec get_event(event_id: Perhap.Event.UUIDv1) :: {:ok, Perhap.Event.t} | {:error, term}
  def get_event(event_id) do
    Agent.get( __MODULE__,
              fn %__MODULE__{events: events, index: _index} ->
                 try do
                   id = event_id |> Perhap.Event.uuid_v1_to_time_order
                   %{^id => event} = events
                   {:ok, event}
                 rescue
                   MatchError -> {:error, "Event not found"}
                 end
               end )
  end

  @spec get_events(atom(), [entity_id: Perhap.Event.UUIDv4.t, after: Perhap.Event.UUIDv1.t, type: atom()]) ::
    {:ok, list(Perhap.Event.t)} | {:error, term}
  def get_events(context, opts \\ []) do
    Agent.get( __MODULE__,
               fn %__MODULE__{events: events, index: index} ->
                 filtered_index  = index
                                   |> filter_index_by_entity_id(context, opts)
                                   |> filter_event_ids_after_a_given_event(opts)
                 filtered_events = events
                                   |> Map.take(filtered_index)
                                   |> Map.values
                                   |> filter_events_by_type(opts)
                 {:ok, filtered_events}
               end )
  end

  defp filter_index_by_entity_id(index, context, opts) do
    case Keyword.has_key?(opts, :entity_id) do
      true ->
        index
        |> Map.get({context, opts[:entity_id]}, [])
      _ ->
        index
        |> Enum.filter(fn {{c, _}, _} -> c == context end)
        |> Enum.map(fn {_, events} -> events end)
        |> List.flatten
    end
  end

  defp filter_event_ids_after_a_given_event(event_ids, opts) do
    case Keyword.has_key?(opts, :after) do
      true ->
        after_event = time_order(opts[:after])
        event_ids |> Enum.filter(fn ev -> ev > after_event end)
      _ -> event_ids
    end
  end

  defp time_order(maybe_uuidv1) do
    case Perhap.Event.is_time_order?(maybe_uuidv1) do
      true -> maybe_uuidv1
      _ -> maybe_uuidv1 |> Perhap.Event.uuid_v1_to_time_order
    end
  end

  def filter_events_by_type(events, opts) do
    case Keyword.has_key?(opts, :type) do
      true ->
        events
        |> Enum.filter(fn %Perhap.Event{metadata: %Perhap.Event.Metadata{type: type}} -> type == opts[:type] end)
      _ ->
        events
    end
  end

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

  def handle_info({:swarm, :die}, state) do
    {:stop, :shutdown, state}
  end
end

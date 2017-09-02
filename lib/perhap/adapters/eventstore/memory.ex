defmodule Perhap.Adapters.Eventstore.Memory do
  use Perhap.Adapters.Eventstore

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
                  fn {events, index} ->
                    events2 = Map.put(events, event[:event_id], event)
                    index_key = { event[:metadata][:context], event[:metadata][:entity_id] }
                    index_value = [ event[:event_id] | Map.get(index, index_key, []) ]
                    index2 = Map.put(index, index_key, index_value)
                    {events2, index2}
                  end )
    :ok
  end

  @spec get_event(event_id: Perhap.Event.UUIDv1) :: {:ok, Perhap.Event.t} | {:error, term}
  def get_event(event_id) do
    Agent.get( __MODULE__,
               fn {events, _index} ->
                 try do
                   %{^event_id => event} = events
                   {:ok, event}
                 rescue
                   MatchError -> {:error, :not_found}
                 end
               end )
  end

  @spec get_events(context: atom()) :: {:ok, list(Perhap.Event.t)} | {:error, term}
  def get_events(context) do
    Agent.get( __MODULE__,
               fn {events, index} ->
                 event_ids = index |> Enum.filter(fn {{c, _}, _} -> c == context end) |> Map.values
                 {:ok, Map.take(events, event_ids)}
               end )
  end

  @spec get_events(context: atom(), entity_id: Perhap.Event.UUIDv4) :: {:ok, list(Perhap.Event.t)} | {:error, term}
  def get_events(context, entity_id) do
    Agent.get( __MODULE__,
               fn {events, index} ->
                 index_key = {context, entity_id}
                 try do
                   %{^index_key => event_ids} = index
                   {:ok, Map.take(events, event_ids)}
                 rescue
                   MatchError -> {:error, :not_found}
                 end
               end )
  end
end

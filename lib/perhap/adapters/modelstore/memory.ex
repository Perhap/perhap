defmodule Perhap.Adapters.Modelstore.Memory do
  use Perhap.Adapters.Modelstore
  use Agent

  @type model :: any()
  @type ledger :: list(Perhap.Event.t)
  @type model_instance :: { Perhap.Event.UUIDv1.t, model, ledger }
  @type key :: { Perhap.Event.UUIDv4.t | :single, module() }
  @type value :: [ versions: list(model_instance), current_events: list(Perhap.Event.t) ]
  @type store :: %{ required(key) => value }
  @type t :: [ modelstore: store, events: list(Perhap.Event.t), config: %{} ]
  defstruct modelstore: %{}, events: [], config: %{}

  @spec start_link(opts: any()) ::   {:ok, pid} | :ignore | {:error, {:already_started, pid} | term}
  def start_link(_opts) do
    Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)
  end

  @spec put_model({Perhap.Event.UUIDv4.t | :single, module()}, Perhap.Event.UUIDv1.t, any()) :: :ok | {:error, term}
  def put_model({entity_id, service}, version, model) do
    Agent.update(__MODULE__,
                fn %__MODULE__{modelstore: store, events: events, config: config} ->
                  store_val = Map.get(store, {entity_id, service}, [versions: %{}, current_events: []])
                  versions = store_val[:versions]
                  {_old_model, ledger} = Map.get(versions, version, {:model, []})
                  store_val = [versions: Map.put(versions, version, {model, ledger}), current_events: store_val[:current_events]]
                  updated_store = Map.put(store, {entity_id, service}, store_val)
                  %__MODULE__{modelstore: updated_store, events: events, config: config}
                end )
    :ok
  end

  @spec get_model({Perhap.Event.UUIDv4.t | :single, module()}, Perhap.Event.UUIDv1.t | nil) :: {:ok, any()} | {:error, term}
  def get_model({entity_id, service}, version \\ nil) do
    Agent.get(__MODULE__,
              fn %__MODULE__{modelstore: store, events: events, config: config} ->
                case Map.get(store, {entity_id, service}) do
                  nil ->
                    {:error, "Model not found"}
                  [versions: versions, current_events: current_events] ->
                    case version do
                      nil ->
                        {:ok, versions}
                      version ->
                        {:ok, Enum.filter(versions, fn {ver_id, _model, _ledger} -> version == ver_id end)}
                    end
                end

              end )
  end
end

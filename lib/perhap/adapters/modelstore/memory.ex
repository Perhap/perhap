defmodule Perhap.Adapters.Modelstore.Memory do
  use Perhap.Adapters.Modelstore
  use Agent

  @type model :: any()
  @type ledger :: list(Perhap.Event.t)
  @type model_instance :: { Perhap.Event.UUIDv1.t, model, ledger }
  @type key :: { Perhap.Event.UUIDv4.t | :single, module() }
  @type value :: [ versions: list(model_instance), current_events: list(Perhap.Event.t) ]
  @type store :: %{ required(key) => value }
  @type t :: [ modelstore: modelstore, 
  defstruct modelstore: [], events: [], config: %{}

  @spec start_link(opts: any()) ::   {:ok, pid} | :ignore | {:error, {:already_started, pid} | term}
  def start_link(_opts) do
    Agent.start_link(fn -> %__MODULE__{} end, name: __MODULE__)
  end

  @spec put_model({Perhap.Event.UUIDv4.t | :single, module()}, Perhap.Event.UUIDv1.t, any()) :: :ok | {:error, term}
  def put_model({entity_id, service}, version, model) do
  end

  @spec get_model({Perhap.Event.UUIDv4.t | :single, module()}, Perhap.Event.UUIDv1.t | nil) :: {:ok, any()} | {:error, term}
  def get_model({entity_id, service}, version \\ nil) do
  end
end

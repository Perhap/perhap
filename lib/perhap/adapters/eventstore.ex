defmodule Perhap.Adapters.Eventstore do
  @moduledoc false

  @callback start_link(opts: any()) ::   {:ok, pid} | :ignore | {:error, {:already_started, pid} | term}
  @callback put_event(event: Perhap.Event.t) :: :ok | {:error, term}
  @callback get_event(event_id: Perhap.Event.UUIDv1) :: {:ok, Perhap.Event.t} | {:error, term}
  @callback get_events(context: atom()) :: {:ok, list(Perhap.Event.t)} | {:error, term}
  @callback get_events(context: atom(), entity_id: Perhap.Event.UUIDv4) :: {:ok, list(Perhap.Event.t)} | {:error, term}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Perhap.Adapters.Eventstore

      @spec start_service(term()) :: {:ok, pid()}
      def start_service(name) do
        {:ok, pid} = Swarm.register_name({__MODULE__, name}, Supervisor, :start_child, [{:via, :swarm, :perhap}, child_spec(name)])
        Swarm.join(:perhap, pid)
        {:ok, :pid}
      end
      def start_service() do
        start_service(__MODULE__)
      end

    end
  end
end

defmodule Perhap.Adapters.Modelstore do
  @moduledoc false

  @callback start_link(opts: any()) ::   {:ok, pid} | :ignore | {:error, {:already_started, pid} | term}
  @callback put_model({Perhap.Event.UUIDv4.t | :single, module()}, Perhap.Event.UUIDv1.t, any()) ::
    :ok | {:error, term}
  @callback get_model({Perhap.Event.UUIDv4.t | :single, module()}, Perhap.Event.UUIDv1.t | nil) ::
    {:ok, any()} | {:error, term}

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Perhap.Adapters.Modelstore

      @spec start_service(term) :: {:ok, pid}
      def start_service(name) do
        {:ok, pid} = Swarm.register_name({__MODULE__, name}, Supervisor, :start_child, [{:via, :swarm, :perhap}, child_spec(name)])
        Swarm.join(:perhap, pid)
        {:ok, pid}
      end
      def start_service() do
        start_service(__MODULE__)
      end

    end
  end
end

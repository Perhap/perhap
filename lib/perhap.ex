defmodule Perhap do
  @moduledoc """
  Documentation for Perhap.

  `use Perhap, app: MyApp`
  """

  defmacro __using__(opts) do
    quote location: :keep do
      use Application
      require Logger
      alias Perhap.PingHandler
      alias Perhap.StatsHandler
      alias Perhap.RootHandler

      import unquote(__MODULE__)

      @app unquote(opts)[:app]
      @defaults protocol: :http,
                bind: unquote(opts)[:bind] || "0.0.0.0",
                port: unquote(opts)[:port] || 4500,
                acceptors: System.schedulers_online * 2,
                max_connections: 65536,
                backlog: 65536

      Module.register_attribute __MODULE__, :routes, accumulate: true, persist: false
      @routes { :_, RootHandler, [] }
      @routes { "/stats", StatsHandler, [] }
      @routes { "/ping", PingHandler, [] }

      @before_compile unquote(__MODULE__)

      def call(_, _), do: true

      def start(:web, args) do
        import Supervisor.Spec
        Logger.debug("Starting Cowboy listener for #{__MODULE__} on " <>
                     "#{config(:protocol) |> to_string}://#{config(:bind)}:#{config(:port)}.")
        { start_function, transport_opts, protocol_opts } = get_cowboy_opts()
        { :ok, _ } = start_function.(__MODULE__, transport_opts, protocol_opts)
        start(:noweb, args)
      end
      def start(:noweb, args) do
        Perhap.Supervisor.start_link(args)
        {:ok, self()}
      end
      def start(_type, args) do
        start(:web, args)
      end

      def start_service({module, entity_id}) do
        {:ok, pid} = Swarm.register_name({module, entity_id}, Perhap.Supervisor, :register, [{module, entity_id}])
        Swarm.join(:perhap, pid)
      end

      def stop(_state) do
        :cowboy.stop_listener(:api_listener)
      end

      def config do
        [ app: @app ] ++
        ( @defaults
          |> Keyword.merge(Application.get_all_env(:perhap)) )
      end

      def config(key) do
        Keyword.get(config(), key)
      end

     defp parse_address(address) when is_binary(address) do
        {:ok, parsed} = :inet.parse_address(address |> to_charlist)
        parsed
      end
      defp parse_address(address) when is_list(address) do
        {:ok, parsed} = :inet.parse_address(address)
        parsed
      end

    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def routes() do
        @routes |> Enum.reverse
      end

      def get_cowboy_opts() do
        transport_opts =  [ ip:              parse_address(config(:bind)),
                            port:            config(:port),
                            num_acceptors:   config(:acceptors),
                            max_connections: config(:max_connections),
                            backlog:         config(:backlog) ]
        ssl_opts       =  [ cacertfile:      config(:cacertfile),
                            certfile:        config(:certfile),
                            keyfile:         config(:keyfile),
                            versions:        [ :'tlsv1.2', :'tlsv1.1', :'tlsv1' ] ]
        protocol_opts  = %{ env:             %{ dispatch: :cowboy_router.compile([{:_, @routes}]) },
                            middlewares:     [ :cowboy_router, :cowboy_handler ],
                            stream_handlers: [ :cowboy_compress_h, :cowboy_stream_h] }
        case config(:protocol) do
          :http  -> { &:cowboy.start_clear/3, transport_opts, protocol_opts }
          :https -> { &:cowboy.start_tls/3, transport_opts ++ ssl_opts, protocol_opts }
        end
      end
    end
  end

  # Context macro and supporting

  @spec context(atom(), [domain: list(tuple())], [single: ( true | false )]) :: Macro.t
  defmacro context(context, domains, opts \\ []) do
    quote bind_quoted: [context: context, domains: domains, opts: opts] do
      for route <- (make_routes(context, domains, opts)), do: @routes route
    end
  end

  def make_routes(context, domains, opts) do
    make_event_routes(context, domains, opts) ++ make_model_routes(context, domains, opts)
    |> List.flatten
  end

  defp make_event_routes(context, domains, opts) do
    Enum.map domains, fn {_domain, spec} ->
      model = Keyword.get(spec, :single, Keyword.get(spec, :model))
      Enum.map Keyword.get(spec, :events), fn event ->
        Perhap.Path.make_event_pathspec( %Perhap.Path.Pathspec{ context: context,
                                                                event_type: event,
                                                                model: model,
                                                                handler: Perhap.Router,
                                                                opts: opts })
      end
    end 
  end

  defp make_model_routes(context, domains, opts) do
    Enum.map domains, fn {domain, spec} ->
      model = Keyword.get(spec, :single, Keyword.get(spec, :model))
      Perhap.Path.make_model_pathspec( %Perhap.Path.Pathspec{ context: context,
                                                              domain: domain,
                                                              model: model,
                                                              handler: Perhap.Router,
                                                              opts: opts ++ [single: Keyword.has_key?(spec, :single)] })
    end
  end

  # Event rewriting and supporting
  defmacro rewrite_event(_path, {_repath, _model}) do
  end

  # Cron and supporting
  defmacro tick(_path, _opts) do
  end

end

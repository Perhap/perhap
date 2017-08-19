defmodule Perhap do
  @moduledoc """
  Documentation for Perhap.

  `use Perhap, app: MyApp`
  """

  defmacro __using__(opts) do
    quote location: :keep do
      use Application
      alias Perhap.PingHandler
      alias Perhap.StatsHandler
      alias Perhap.RootHandler

      import unquote(__MODULE__)

      @app unquote(opts)[:app]
      @defaults protocol: :http,
                bind: "0.0.0.0",
                port: 4500,
                acceptors: System.schedulers_online * 2,
                max_connections: 65536,
                backlog: 65536

      Module.register_attribute __MODULE__, :routes, accumulate: true, persist: false
      @routes { :_, RootHandler, [] }
      @routes { "/stats", StatsHandler, [] }
      @routes { "/ping", PingHandler, [] }

      @before_compile unquote(__MODULE__)

      def call(_, _), do: true

      def start(_type, _args) do
        import Supervisor.Spec
        { start_function, transport_opts, protocol_opts } = get_cowboy_opts()
        { :ok, _ } = start_function.(:api_listener, transport_opts, protocol_opts)
        children = [ supervisor(Task.Supervisor, [[name: Perhap.TaskSupervisor]]) ]
        Supervisor.start_link(children, [strategy: :one_for_one, name: Perhap.Supervisor])
      end

      def stop(_state) do
        :cowboy.stop_listener(:api_listener)
      end

      def config do
        [ app: @app ] ++
        ( @defaults
          |> Keyword.merge(Application.get_env(@app, :perhap)) )
      end

      def config(key) do
        Keyword.get(config(), key)
      end

      defp get_cowboy_opts() do
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
    end
  end

  # Context macro and supporting

  defmacro context(context, domains, opts \\ []) do
    quote bind_quoted: [context: context, domains: domains, opts: opts] do
      Enum.each (make_routes(context, domains, opts)),
                 fn route ->
                   @routes route
                 end
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
        Perhap.Router.make_event_path( %{ context: context,
                                          event_type: event,
                                          model: model,
                                          opts: opts })
      end
    end 
  end

  defp make_model_routes(context, domains, opts) do
    Enum.map domains, fn {domain, spec} ->
      model = Keyword.get(spec, :single, Keyword.get(spec, :model))
      Perhap.Router.make_model_path( %{ context: context,
                                        domain: domain,
                                        model: model,
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

defmodule Perhap do
  @moduledoc """
  # Perhap

  Perhap is a framework for building reactive systems using domain driven design ("reactive domain driven design" or "rDDD".)

  ## Usage
  
  Include Perhap in your application:

  ```
  defmodule MyApp do
    use Perhap, app: my_app
    ...
  ```

  Then, specify at least one bounded context with at least one domain service, and tell Perhap what events you want:

  ```
  context :my_bounded_context,
    domain: [ model: MyApp.MyDomainService,
              events: [:myevent1, :myevent2] ]
  ```

  Perhap will generate routes for POSTing events, retrieving events, and retrieving models. Your domain service will receive the events and update a model, returning a tuple with the transformed model and a list of new events.

  In your domain service, include Perhap.Domain, set your initial model state, and implement a `reducer` function.

  ```
  defmodule MyApp.MyDomainService do
    use Perhap.Domain
    @initial_state 0

    def reducer({:myevent1, model, event}) do
      model + 1
    end
    ...
  ```

  To interact with Perhap at a basic level:
  
  * POST events to `http[s]://your_server.tld/your_context/your_event_type/your_entity_id/your_event_id`, where `your_context` is a context you've defined, `your_event_type` is an event type your domain service(s) care about, `your_entity_id` is a UUIDv4 identifier, and `your_event_id` is a UUIDv1 identifier.
  * GET models from `http[s]://your_server.tld/your_context/your_domain_service/your_entity_id`, where `your_context` is a context you've defined, `your_domain_service` is a domain service you specified, and `your_entity_id` is one of your UUIDv4 identifiers.

  ## Configuration

  `use Perhap, options` where options is a keyword list

  * `app:` The name of the application.
  * `protocol:` Override the default protocol (http).
  * `listen:` Override the default listen address (127.0.0.1).
  * `port:` Override the default listen port (4580).
  * `auth:` The module providing authentication.
  * `eventstore:` The module providing event persistence.
  * `modelstore:` The module providing model persistence.

  In addition to the options in the `use Perhap` statement, these options can be set in `config.exs`:

  * `cacertfile:` path to the cacertfile
  * `certfile:` path to the certfile
  * `keyfile:` path to the keyfile

  Also can be set using the system environment:

  * `PERHAP_PROTOCOL` - `http` or `https`
  * `PERHAP_BIND` - dot-quad notation
  * `PERHAP_PORT` - port number
  * `PERHAP_CACERTFILE` - path to cacertfile
  * `PERHAP_CERTFILE` - path to certfile
  * `PERHAP_KEYFILE` - path to keyfile
  """

  defmacro __using__(opts) do
    quote location: :keep do
      use Application
      use Supervisor
      require Logger

      import unquote(__MODULE__)

      @app unquote(opts)[:app]
      @config protocol: unquote(opts)[:protocol] || :http,
              listen: unquote(opts)[:listen] || "127.0.0.1",
              port: unquote(opts)[:port] || 4580,
              max_connections: 65536,
              backlog: 65536,
              eventstore: unquote(opts)[:eventstore] || Perhap.Adapters.Eventstore.Memory,
              modelstore: unquote(opts)[:modelstore] || Perhap.Adapters.Modelstore.Memory

      Module.register_attribute __MODULE__, :routes, accumulate: true, persist: false
      Module.register_attribute __MODULE__, :route_table, accumulate: false, persist: false
      @routes { :_, Perhap.RootHandler, [] }
      @routes { "/stats", Perhap.StatsHandler, []}
      @routes { "/ping", Perhap.PingHandler, [] }

      @before_compile unquote(__MODULE__)

      def event(%{ context: context,
                   event_type: event_type,
                   entity_id: entity_id,
                   event_id: event_id,
                   data: data}) do
        event = %Perhap.Event{ event_id: event_id,
                  metadata: %Perhap.Event.Metadata{
                    event_id: event_id,
                    entity_id: entity_id,
                    context: context,
                    type: event_type,
                    user_id: nil,
                    timestamp: Perhap.Event.timestamp() },
                  data: data }
        { _path, _handler, opts } = find_route("/#{context |> to_string}/#{event_type |> to_string}/:entity_id/:event_id")
        opts2 = Keyword.merge(opts, [entity_id: entity_id, event_id: event_id])
        case Perhap.Event.validate(event) do
          :ok ->
            Perhap.Event.save_event!(event)
            Perhap.Dispatcher.ensure_started({Perhap.Dispatcher, __MODULE__})
            Perhap.Dispatcher.dispatch({Perhap.Dispatcher, __MODULE__}, event, opts2)
          {:invalid, reason} ->
            raise(RuntimeError, message: reason)
        end
      end

      def model(context, domain, entity_id \\ nil) do
        route = "/#{context |> to_string}/#{domain |> to_string}/#{if entity_id, do: ":entity_id/", else: ""}model"
        { _path, _handler, opts } = find_route(route)
        ({module, _} = child) = case opts[:model] do
          {module, :single} -> {module, :single}
          module -> {module, entity_id}
        end
        case apply(module, :retrieve, [child]) do
          {:ok, model} ->
            model
          e ->
            raise(RuntimeError, message: "Model not found")
        end
      end

      def call(_, _), do: true

      def start(:web, args) do
        IO.puts("Starting Cowboy listener for #{__MODULE__} on " <>
                     "#{config(:protocol) |> to_string}://#{config(:listen)}:#{config(:port)}.")
        { start_function, transport_opts, protocol_opts } = get_cowboy_opts()
        try do
          start_function.(:perhap, transport_opts, protocol_opts)
        rescue
          any -> Logger.warn("Could not start Cowboy listener: #{inspect any}")
        end
        start(:noweb, args)
      end
      def start(:noweb, args) do
        config() |> Enum.each(fn {k, v} -> Application.put_env(@app, k, v, [:persistent]) end)
        try do
          Supervisor.start_link(__MODULE__, args, name: {:via, :swarm, :perhap})
        rescue
          any -> Logger.warn("Could not start Perhap supervisor: #{inspect any}")
        end
        try do
          apply(config(:eventstore), :start_service, [])
        rescue
          any -> Logger.warn("Could not start eventstore: #{inspect any}")
        end
        {:ok, self()}
      end
      def start(_type, _args) do
        start()
      end
      def start() do
        start(:web, nil)
      end

      def init(_arg) do
        Supervisor.init([], strategy: :one_for_one)
      end

      @spec start_service(module(), term()) :: {:ok, pid()}
      def start_service(module, name) do
        {:ok, pid} = Swarm.register_name({module, name}, Supervisor, :start_child, [{:via, :swarm, :perhap}, apply(module, :child_spec, [name])])
        Swarm.join(:perhap, pid)
        {:ok, pid}
      end
      def start_service(module) do
        # no name given so use the module as name
        start_service(module, module)
      end

      def stop_service(name) do
        Supervisor.terminate_child({:via, :swarm, :perhap}, name)
      end

      def stop(_state) do
      end

      def config() do
        [ app: @app ] ++
        ( @config
          |> Keyword.merge(Application.get_all_env(:perhap))
          |> Keyword.merge(system_environment()) )
      end

      def config(key) do
        Keyword.get(config(), key)
      end

      defp system_environment() do
      [ case System.get_env("PERHAP_PROTOCOL") do
          "https" -> [ protocol: :https ]
          "http"  -> [ protocol: :http ]
          _       -> nil
        end,
        case System.get_env("PERHAP_LISTEN") do
          nil     -> nil
          address -> [ listen: address ]
        end,
        case System.get_env("PERHAP_PORT") do
          nil  -> nil
          port -> [ port: port |> String.to_integer ]
        end,
        case System.get_env("PERHAP_CACERTFILE") do
          nil  -> nil
          cert -> [ cacertfile: cert ]
        end,
        case System.get_env("PERHAP_CERTFILE") do
          nil  -> nil
          cert -> [ certfile: cert ]
        end,
        case System.get_env("PERHAP_KEYFILE") do
          nil -> nil
          key -> [ keyfile: key ]
        end ] |> Enum.filter(fn x -> x end) |> List.flatten
      end

      defp parse_address(address) when is_binary(address) do
        {:ok, parsed} = :inet.parse_address(address |> to_charlist)
        parsed
      end
      defp parse_address(address) when is_list(address) do
        {:ok, parsed} = :inet.parse_address(address)
        parsed
      end

      def get_cowboy_opts() do
        transport_opts =  [ ip:              parse_address(config(:listen)),
                            port:            config(:port),
                            num_acceptors:   config(:acceptors) || System.schedulers_online * 2,
                            max_connections: config(:max_connections),
                            backlog:         config(:backlog) ]
        ssl_opts       =  [ cacertfile:      config(:cacertfile),
                            certfile:        config(:certfile),
                            keyfile:         config(:keyfile),
                            versions:        [ :'tlsv1.2', :'tlsv1.1', :'tlsv1' ] ]
        protocol_opts  = %{ env:             %{ dispatch: :cowboy_router.compile([{:_, routes()}]) },
                            middlewares:     [ :cowboy_router, :cowboy_handler ],
                            stream_handlers: [ :cowboy_compress_h, :cowboy_stream_h] }
        case config(:protocol) do
          :http  -> { &:cowboy.start_clear/3, transport_opts, protocol_opts }
          :https -> { &:cowboy.start_tls/3, transport_opts ++ ssl_opts, protocol_opts }
        end
      end
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @route_table Perhap.Path.make_route_table(@routes)

      def routes() do
        @route_table |> Enum.reverse
      end

      def find_route(path) do
        routes()
        |> Enum.filter(fn({path2, _handler, _state}) -> path2 == path end)
        |> List.first
      end
    end
  end

  # Context macro and supporting

  @spec context(atom(), [domain: list(tuple())], [single: ( true | false )]) :: Macro.t
  defmacro context(context, domains, opts \\ []) do
    quote bind_quoted: [context: context, domains: domains, opts: opts] do
      for route <- make_routes(context, domains, opts), do: @routes route
    end
  end

  def make_routes(context, domains, opts) do
    [ make_post_event_routes(context, domains, opts),
      make_model_routes(context, domains, opts),
      make_get_event_routes(context, opts),
      make_get_events_routes(context, opts) ] |> List.flatten
  end

  defp make_post_event_routes(context, domains, opts) do
    Enum.map domains, fn {_domain, spec} ->
      model = Keyword.get(spec, :single, Keyword.get(spec, :model))
      opts2 = Keyword.merge(opts, [handler: :post_event, context: context, single: Keyword.has_key?(spec, :single)])
      Enum.map Keyword.get(spec, :events), fn event ->
        Perhap.Path.make_post_event_pathspec( %Perhap.Path.Pathspec{ context: context,
                                                                     event_type: event,
                                                                     model: model,
                                                                     handler: Perhap.EventHandler,
                                                                     opts: opts2 })
      end
    end 
  end

  def make_get_event_routes(context, opts) do
    opts2 = Keyword.merge(opts, [handler: :get_event, context: context])
    Perhap.Path.make_get_event_pathspec( %Perhap.Path.Pathspec{ context: context,
                                                                handler: Perhap.EventHandler,
                                                                opts: opts2 })
  end

  def make_get_events_routes(context, opts) do
    opts2 = Keyword.merge(opts, [handler: :get_events, context: context])
    Perhap.Path.make_get_events_pathspec( %Perhap.Path.Pathspec{ context: context,
                                                                 handler: Perhap.EventHandler,
                                                                 opts: opts2 })
  end

  defp make_model_routes(context, domains, opts) do
    Enum.map domains, fn {domain, spec} ->
      opts2 = Keyword.merge(opts, [handler: :get_model,
                                   context: context,
                                   single: Keyword.has_key?(spec, :single)])
      model = Keyword.get(spec, :single, Keyword.get(spec, :model))
      Perhap.Path.make_model_pathspec( %Perhap.Path.Pathspec{ context: context,
                                                              domain: domain,
                                                              model: model,
                                                              handler: Perhap.ModelHandler,
                                                              opts: opts2 })
    end
  end

  # Event rewriting and supporting
  defmacro rewrite_event(_path, {_repath, _model}) do
  end

  # Cron and supporting
  defmacro tick(_path, _opts) do
  end

end

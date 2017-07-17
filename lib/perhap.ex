alias Perhap.Monitoring
alias Perhap.PingHandler
alias Perhap.RootHandler

defmodule Perhap do
  @moduledoc """
  Documentation for Perhap.

  `use Perhap, app: MyApp`
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use Application

      @defaults [
        network: [
          protocol: :http,
          bind: {'0.0.0.0', 4500},
          acceptors: System.schedulers_online * 2
        ]
      ]

      def config do
        [app: opts[:app]] ++
        (@default_config |> Keyword.merge(Application.get_env(opts[:app], :perhap)))
      end

      def config(section, key) do
        config()[:section][:key]
      end

      def start(_type, _args) do
        start_cowboy()
        start_link()
      end

      def stop(_state) do
        :cowboy.stop_listener(:api_listener)
      end

     defp start_cowboy() do
        {cowboy_start_fun, protocol_opts} = case config(:network, :protocol) do
          :http ->  {&:cowboy.start_clear/3, nil}
          :https -> {&:cowboy.start_tls/3, get_ssl_opts()}
        end
        {:ok, _} = cowboy_start_fun.(:api_listener, ranch_tcp_opts(protocol_opts), cowboy_opts(dispatcher()))
      end

      defp start_link() do
        import Supervisor.Spec, warn: false
        children = [
          supervisor(Task.Supervisor, [[name: Perhap.TaskSupervisor]])
        ]
        opts = [strategy: :one_for_one, name: Perhap.Supervisor]
        Supervisor.start_link(children, opts)
      end

      defp dispatcher do
        :cowboy_router.compile([
          {:_, [
            {"/ping", PingHandler, []},
            #{"/event/:event_id", EventHandler, []},
            #{"/event/:realm/:domain/:entity_id/:type/:event_id", EventHandler, []},
            #{"/events/:domain/:entity_id", EventsHandler, []},
            #{"/model/:domain/:entity_id", ModelHandler, []},
            #{"/stats", StatsHandler, []},
            #{"/ws", WSHandler, []},
            {:_, RootHandler, []}
          ]}
        ])
      end

      defp ranch_tcp_opts(protocol_opts) do
        {raw_ip, port} = config(:network, :bind)
        {_, ip} = :inet.parse_address(raw_ip)
        [
          ip: ip,
          port: port,
          num_acceptors: config(:network, :acceptors),
          max_connections: 16384,
          backlog: 32768
        ] ++ (protocol_opts || [])
      end

      defp cowboy_opts() do
        %{
          env: %{dispatch: dispatcher()},
          middlewares: [
            Monitoring.First,
            :cowboy_router,
            :cowboy_handler,
            Monitoring.Last
          ],
          stream_handlers: [:cowboy_compress_h, :cowboy_stream_h]
        }
      end

      defp get_ssl_opts() do
        [cacertfile: config(:ssl, :cacertfile),
         certfile: config(:ssl, :certfile),
         keyfile: config(:ssl, :keyfile),
         versions: [:'tlsv1.2', :'tlsv1.1', :'tlsv1']]
      end
    end
  end
end

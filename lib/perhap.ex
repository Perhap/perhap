defmodule Perhap do
  @moduledoc """
  Documentation for Perhap.

  `use Perhap, app: MyApp`
  """

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use Application

      @defaults [ network: [
                  protocol: :http,
                  bind: {'0.0.0.0', 4500},
                  acceptors: System.schedulers_online * 2 ] ]

      @app opts[:app]

      def config do
        [app: @app] ++
        (@defaults |> Keyword.merge(Application.get_env(@app, :perhap)))
      end

      def config(section, key) do
        config()[:section][:key]
      end

      def start(_type, _args) do
        import Supervisor.Spec
 
        {raw_ip, port} = config(:network, :bind)
        {_, ip} = :inet.parse_address(raw_ip)
        children = [
          Plug.Adapters.Cowboy.child_spec(config(:network, :protocol),
                                          Perhap.Router,
                                          [],
                                          [port: port])]
        Supervisor.start_link(children, [strategy: :one_for_one, name: Perhap.Supervisor])
      end

      def stop(_state) do
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

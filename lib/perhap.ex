defmodule Perhap do
  @moduledoc """
  Documentation for Perhap.

  `use Perhap, app: MyApp`
  """

  defmacro __using__(opts) do
    quote location: :keep do
      use Application
      use Plug.ErrorHandler
      import Perhap.Context
      import unquote(__MODULE__)

      Module.register_attribute __MODULE__, :routes, accumulate: true, persist: false

      @app unquote(opts)[:app]
      @defaults [ network: [
                  protocol: :http,
                  bind: {'0.0.0.0', 4500},
                  acceptors: System.schedulers_online * 2 ] ]

      @before_compile unquote(__MODULE__)

      def call(_,_), do: true

      def start(_type, _args) do
        import Supervisor.Spec

        {raw_ip, port} = config(:network, :bind)
        {_, ip} = :inet.parse_address(raw_ip)
        children = [
          Plug.Adapters.Cowboy.child_spec(config(:network, :protocol),
                                          Perhap.Router, [], [port: port])]
        Supervisor.start_link(children, [strategy: :one_for_one, name: Perhap.Supervisor])
      end

      def stop(_state) do
      end


      def config do
        [app: @app] ++
        (@defaults |> Keyword.merge(Application.get_env(@app, :perhap)))
      end

      def config(section, key) do
        config()[:section][:key]
      end


      defp get_ssl_opts() do
        [cacertfile: config(:ssl, :cacertfile),
         certfile: config(:ssl, :certfile),
         keyfile: config(:ssl, :keyfile),
         versions: [:'tlsv1.2', :'tlsv1.1', :'tlsv1']]
      end
    end
  end

  defmacro context(context, domains) do
    quote bind_quoted: [context: context, domains: domains] do
      Enum.each domains, fn d ->
        @routes context: context, domain: d
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

end

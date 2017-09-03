use Mix.Config

config :perhap,
  eventstore: Perhap.Adapters.Eventstore.Memory,
  modelstore: Perhap.Adapters.Modelstore.Memory

config :ssl, protocol_version: :"tlsv1.2"

config :logger,
  backends: [:console],
  utc_log: true,
  compile_time_purge_level: :debug,
  level: :error

config :logger, :access_log,
  metadata: [:application, :module, :function],
  level: :info

config :logger, :error_log,
  metadata: [:application, :module, :function, :file, :line],
  level: :error

config :libcluster,
  topologies: [
    perhap: [ strategy: Cluster.Strategy.Epmd,
              config: [hosts: [:"perhap1@127.0.0.1"] ]]
  ]

config :swarm,
  sync_nodes_timeout: 1_000

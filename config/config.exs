use Mix.Config

config :ssl, protocol_version: :"tlsv1.2"

config :logger,
  backends: [:console],
  utc_log: true,
  compile_time_purge_level: :debug

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

config :swarm, debug: true

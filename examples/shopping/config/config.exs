# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :perhap,
  port: 9000

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
              config: [hosts: [:"shopping@127.0.0.1"] ]]
  ]

config :swarm, node_whitelist: [~r/^shopping[\d]@.*$/], sync_nodes_timeout: 1000 #debug: true

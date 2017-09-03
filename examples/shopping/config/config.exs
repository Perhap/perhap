# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :perhap,
  port: 9000,
  eventstore: Doesnt.Exist

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

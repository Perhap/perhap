# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :perhap,
  port: 9000

config :logger,
  backends: [:console],
  compile_time_purge_level: :info,
  level: :warn

config :swarm,
  sync_nodes_timeout: 10

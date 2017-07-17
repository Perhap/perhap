defmodule Perhap.Config do
  def get_protocol(), do:
      :proplists.get_value(:protocol, get_env(:network))

  def get_bind_address(), do:
      :proplists.get_value(:bind, get_env(:network))

  def get_num_acceptors(), do:
      :proplists.get_value(:acceptors, get_env(:network))

  def get_ssl_cacertfile(), do:
      :proplists.get_value(:cacertfile, get_env(:ssl))

  def get_ssl_certfile(), do:
      :proplists.get_value(:certfile, get_env(:ssl))

  def get_ssl_keyfile(), do:
      :proplists.get_value(:keyfile, get_env(:ssl))

  defp get_env(key) do
      {_, value} = :application.get_env(:api, key)
      value
  end
end

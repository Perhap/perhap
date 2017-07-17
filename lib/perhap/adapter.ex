defmodule Perhap.Adapter do
  @moduledoc """
  This module specifies the adapter API that an adapter is required to implement.
  """

  @type t :: module

  @doc """
  The callback invoked in case the adapter needs to inject code.
  """
  @macrocallback __before_compile__(env :: Macro.Env.t) :: Macro.t
end


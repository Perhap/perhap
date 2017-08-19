defmodule Perhap.Domain do
  @callback reduce(atom(), map(), list(map())) :: { map(), list(map()) }
end

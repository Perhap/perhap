defmodule Perhap.Handler do

  defmacro __using__(_) do
    quote do
      require Logger
      def terminate(reason, request, state) do
        case reason do
          :normal -> :ok
          {:crash, status, type} ->
            Logger.error("Handler Crash: #{inspect(status)}/#{inspect(type)}")
            :error
          _ ->
            Logger.debug("Terminating for reason: #{inspect(reason)}")
            :error
        end
      end
    end
  end

end

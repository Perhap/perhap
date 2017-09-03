defmodule Perhap.Handler do

  defmacro __using__(_) do
    quote do
      require Logger
      @callback handle(String.t, :cowboy_req.req(), any()) ::
                  { :ok | :error | :exit | :throw, :cowboy_req.req(), any()}

      @read_length 1048576
      @timeout 1000

      def init(req0, state) do
        try do
          method = :cowboy_req.method(req0)
          state1 = Keyword.merge(state, Map.to_list(req0.bindings))
          {:ok, handle(Keyword.get(state1, :handler, method), req0, state1), state1}
        rescue
          any ->
            Logger.debug("[perhap] bad request: #{inspect(any)}")
            Perhap.Response.send(req0, Perhap.Error.make(Map.get(any, :message, inspect(any))))
        end
      end

      def terminate(reason, request, state, module) do
        case reason do
          :normal -> :ok
          {:crash, status, type} ->
            Logger.error("Handler crash in module #{inspect(module)}: #{inspect(status)}/#{inspect(type)}")
            :error
          _ ->
            Logger.debug("Terminating for reason in module #{inspect(module)}: #{inspect(reason)}")
            :error
        end
      end

      defp set_response_header(conn, header, value) do
        :cowboy_req.set_resp_header(header, value, conn)
      end
    end
  end

end

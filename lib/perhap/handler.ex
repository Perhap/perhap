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
          {:ok, handle(method, req0, state), state}
        rescue 
          any ->
            Perhap.Response.send(req0, Perhap.Error.make(any.message))
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

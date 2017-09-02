Code.require_file("./support/perhap_fixture.exs", __DIR__)
Code.require_file("./support/domain_fixture.exs", __DIR__)
ExUnit.start()

defmodule PerhapTest.Helper do

  defmacro __using__(opts) do
    quote location: :keep do

      @port unquote(opts)[:port]

      def get(url) do
        :application.ensure_all_started(:gun)
        {:ok, pid} = :gun.open('localhost', @port)
        stream_ref = :gun.get(pid, url)
        read_stream(pid, stream_ref)
      end

      def post(body, url) do
        :application.ensure_all_started(:gun)
        {:ok, pid} = :gun.open('localhost', @port)
        stream_ref = :gun.post(pid, url, [
                                 {"content-type", 'application/json'}
                               ], body)
        read_stream(pid, stream_ref)
      end

      def options(url) do
        :application.ensure_all_started(:gun)
        {:ok, pid} = :gun.open('localhost', @port)
        stream_ref = :gun.options(pid, url)
        read_stream(pid, stream_ref)
      end

      defp read_stream(pid, stream_ref) do
        case :gun.await(pid, stream_ref) do
          {:response, :fin, status, headers} ->
            %{status: status, headers: headers}
          {:response, :nofin, status, headers} ->
            {:ok, body} = :gun.await_body(pid, stream_ref)
            %{body: body, headers: headers, status: status}
        end
      end
    end
  end
end

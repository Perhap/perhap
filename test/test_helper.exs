Code.require_file("./support/fixture.exs", __DIR__)
Fixture.start()
ExUnit.start()

defmodule PerhapTest.Helper do

  defmacro __using__(opts) do
    quote location: :keep do
      use ExUnit.Case, async: true
      require Fixture
      import PerhapTest.Helper, only: :functions

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
        stream_ref = :gun.post(pid, url,
                               [ {"content-type", 'application/json'} ],
                               body)
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

  def make_random_event(), do: make_random_event(%Perhap.Event.Metadata{})
  def make_random_event(%Perhap.Event.Metadata{} = metadata) do
    event_id = metadata.event_id || Perhap.Event.get_uuid_v1()
    %Perhap.Event{
      event_id: event_id,
      data: %{:random_number => :rand.uniform(1000)},
      metadata: %{
        metadata |
          event_id: event_id,
          entity_id: metadata.entity_id || Perhap.Event.get_uuid_v4(),
          type: metadata.type || :random_event,
          timestamp: metadata.timestamp || Perhap.Event.timestamp() }
    }
  end
end

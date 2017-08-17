Code.require_file("./support/perhaptest_fixture.exs", __DIR__)
ExUnit.start()

defmodule PerhapTest.Helper do
  #  @spec load_fixture(String.t) :: binary()
  #  def load_fixture(fixture_file) do
  #    {:ok, binary} = File.read "test/fixtures/" <> fixture_file
  #    binary
  #  end
  #
  #  @spec generate_event(String.t) :: DB.Event.t
  #  def generate_event(fixture_file) do
  #    {uuid_v1, _} = :uuid.get_v1(:uuid.new(self(), :erlang))
  #    event_id = to_string(:uuid.uuid_to_string(uuid_v1))
  #    entity_id = to_string(:uuid.uuid_to_string(:uuid.get_v4(:strong)))
  #    meta = load_fixture(fixture_file) |> JSON.decode!
  #    generated = %{
  #      realm: "test_company", type: "start",
  #      domain: "challenge", event_id: event_id, entity_id: entity_id, meta: meta}
  #    struct(DB.Event, generated)
  #  end

  def get(url) do
    :application.ensure_all_started(:gun)
    {:ok, pid} = :gun.open('localhost', 4499)
    stream_ref = :gun.get(pid, url)
    read_stream(pid, stream_ref)
  end

  def post(body, url) do
    :application.ensure_all_started(:gun)
    {:ok, pid} = :gun.open('localhost', 4499)
    stream_ref = :gun.post(pid, url, [
      {"content-type", 'application/json'}
    ], body)
    read_stream(pid, stream_ref)
  end

  def options(url) do
    :application.ensure_all_started(:gun)
    {:ok, pid} = :gun.open('localhost', 4499)
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

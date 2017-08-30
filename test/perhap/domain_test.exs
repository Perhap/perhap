defmodule PerhapTest.Domain do
  use ExUnit.Case, async: true
  use PerhapTest.Helper, port: 4498
  import PerhapTest.Helper
  require PerhapFixture.Domain, as: Fixture

  setup_all do
    Fixture.start(nil, nil)
    {:ok, pid} = GenServer.start_link(PerhapFixture.Domain.Domain1, 0)
    on_exit fn ->
      :ok
    end
    {:ok, [pid: pid]}
  end

  test "Start a domain and retrieve initial state", context do
    assert {:ok, 0} == GenServer.call(context[:pid], {:retrieve, []})
  end

  test "Cast a message and update state", _context do
    event = %Perhap.Event{ event_id: Perhap.Event.get_uuid_v1(),
                           data: %{},
                           metadata: %Perhap.Event.Metadata{} }
    { :noreply, state } = PerhapFixture.Domain.Domain1.handle_cast({:reduce, [event]}, 0)
    assert {:reply, { :ok, 1 }, 1} ==
      PerhapFixture.Domain.Domain1.handle_call({:retrieve, []}, nil, state)
  end

  test "Register a domain service" do
    Perhap.Supervisor.register({PerhapFixture.Domain.Domain1, [:domain1]})
  end
end

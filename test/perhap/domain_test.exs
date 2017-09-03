defmodule PerhapTest.Domain do
  use PerhapTest.Helper, port: 4499

  setup_all do
    {:ok, pid} = Fixture.start_service(Fixture.Domain1, :domain1)
    on_exit fn ->
      Fixture.stop_service(Fixture.Domain1)
    end
    [pid: pid]
  end

  test "Start a domain and retrieve initial state", %{pid: pid} do
    assert {:ok, 0} == GenServer.call(pid, {:retrieve, []})
  end

  test "Cast a message and update state", _context do
    event = %Perhap.Event{ event_id: Perhap.Event.get_uuid_v1(),
                           data: %{},
                           metadata: %Perhap.Event.Metadata{} }
    { :noreply, state } = Fixture.Domain1.handle_cast({:reduce, [event]}, 0)
    assert {:reply, { :ok, 1 }, 1} ==
      Fixture.Domain1.handle_call({:retrieve, []}, nil, state)
  end

  test "Register a domain service", %{pid: pid} do
    refute Swarm.Registry.get_by_pid(pid) == :undefined
  end
end

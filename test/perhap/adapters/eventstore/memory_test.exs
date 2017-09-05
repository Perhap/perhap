defmodule PerhapTest.Adapters.Memory do
  use PerhapTest.Helper, port: 4499
  alias Perhap.Adapters.Eventstore.Memory

  test "put_event" do
    initial_state = :sys.get_state(Memory)
    Memory.put_event(make_random_event())
    refute :sys.get_state(Memory) == initial_state
  end

  test "get_event" do
    random_context = Enum.random([:a, :b, :c, :d, :e])
    rando = make_random_event( 
      %Perhap.Event.Metadata{context: random_context, entity_id: Perhap.Event.get_uuid_v4()} )
    Memory.put_event(rando)
    assert Memory.get_event(rando.event_id) == {:ok, rando}
  end

  test "get_events with entity_id" do
    random_context = Enum.random([:a, :b, :c, :d, :e])
    random_entity_id = Perhap.Event.get_uuid_v4()
    rando1 = make_random_event( 
      %Perhap.Event.Metadata{context: random_context, entity_id: random_entity_id} )
    Memory.put_event(rando1)
    rando2 = make_random_event( 
      %Perhap.Event.Metadata{context: random_context, entity_id: random_entity_id} )
    Memory.put_event(rando2)
    assert Memory.get_events(random_context, random_entity_id) == {:ok, [rando1, rando2]}
  end

  test "get_events without entity_id" do
    random_context = Enum.random([:f, :g, :h, :i, :j])
    random_entity_id = Perhap.Event.get_uuid_v4()
    rando1 = make_random_event( 
      %Perhap.Event.Metadata{context: random_context, entity_id: random_entity_id} )
    Memory.put_event(rando1)
    rando2 = make_random_event( 
      %Perhap.Event.Metadata{context: random_context, entity_id: random_entity_id} )
    Memory.put_event(rando2)
    assert Memory.get_events(random_context) == {:ok, [rando1, rando2]}
  end

end

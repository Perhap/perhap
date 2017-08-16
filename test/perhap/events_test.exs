defmodule Perhap.EventsTest do
  use ExUnit.Case, async: true
  alias Perhap.Events

  defp make_v1() do
    {uuid, _} = :uuid.get_v1(:uuid.new(self()))
    uuid |> :uuid.uuid_to_string |> to_string()
  end

  defp make_v4() do
    :uuid.get_v4() |> :uuid.uuid_to_string |> to_string()
  end

  test "timestamp returns system time in microseconds" do
    assert_in_delta(Events.timestamp(), :erlang.system_time(:microsecond), 10)
  end

  test "unique_integer returns monotonically increasing integers" do
    unique_integers = for _n <- 1..10, do: Events.unique_integer()
    assert unique_integers == Enum.sort(unique_integers |> Enum.dedup)
  end

  test "get_uuid_v1 returns valid uuid_v1" do
    assert :uuid.is_v1(Events.get_uuid_v1() |> :uuid.string_to_uuid)
  end

  test "knows a uuid_v1 when it sees one" do
    assert Events.is_uuid_v1?(make_v1())
  end

  test "flips the time so it can be sorted, and back again" do
    uuid = make_v1()
    [ulow, umid, uhigh, _, _] = String.split(uuid, "-")
    flipped = Events.uuid_v1_to_time_order(uuid)
    [fhigh, fmid, flow, _, _] = String.split(flipped, "-")
    double_flipped = Events.time_order_to_uuid_v1(flipped)
    refute uuid == flipped
    assert uuid == double_flipped
    assert {ulow, umid, uhigh} == {flow, fmid, fhigh}
  end

  test "extract datetime returns the time the event was created" do
    uuid_time = make_v1() |> Events.extract_uuid_v1_time
    system_time = System.system_time(:microsecond)
    assert_in_delta(system_time, uuid_time, 10000)
  end

  test "returns a valid uuid_v4" do
    assert :uuid.is_v4(Events.get_uuid_v4() |> :uuid.string_to_uuid())
  end

  test "knows a valid uuid_v4 when it sees one" do
    assert Events.is_uuid_v4?(make_v4())
  end
end

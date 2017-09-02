defmodule Perhap.EventTest do
  use ExUnit.Case, async: true

  defp make_v1() do
    {uuid, _} = :uuid.get_v1(:uuid.new(self()))
    uuid |> :uuid.uuid_to_string |> to_string()
  end

  defp make_v4() do
    :uuid.get_v4() |> :uuid.uuid_to_string |> to_string()
  end

  test "timestamp returns system time in microseconds" do
    assert_in_delta(Perhap.Event.timestamp(), :erlang.system_time(:microsecond), 10)
  end

  test "unique_integer returns monotonically increasing integers" do
    unique_integers = for _n <- 1..10, do: Perhap.Event.unique_integer()
    assert unique_integers == Enum.sort(unique_integers |> Enum.dedup)
  end

  test "get_uuid_v1 returns valid uuid_v1" do
    assert :uuid.is_v1(Perhap.Event.get_uuid_v1() |> :uuid.string_to_uuid)
  end

  test "knows a uuid_v1 when it sees one" do
    assert Perhap.Event.is_uuid_v1?(make_v1())
  end

  test "flips the time so it can be sorted, and back again" do
    uuid = make_v1()
    [ulow, umid, uhigh, _, _] = String.split(uuid, "-")
    flipped = Perhap.Event.uuid_v1_to_time_order(uuid)
    [fhigh, fmid, flow, _, _] = String.split(flipped, "-")
    double_flipped = Perhap.Event.time_order_to_uuid_v1(flipped)
    refute uuid == flipped
    assert uuid == double_flipped
    assert {ulow, umid, uhigh} == {flow, fmid, fhigh}
  end

  test "extract datetime returns the time the event was created" do
    uuid_time = make_v1() |> Perhap.Event.extract_uuid_v1_time
    system_time = System.system_time(:microsecond)
    assert_in_delta(system_time, uuid_time, 100_000)
  end

  test "returns a valid uuid_v4" do
    assert :uuid.is_v4(Perhap.Event.get_uuid_v4() |> :uuid.string_to_uuid())
  end

  test "knows a valid uuid_v4 when it sees one" do
    assert Perhap.Event.is_uuid_v4?(make_v4())
  end
end

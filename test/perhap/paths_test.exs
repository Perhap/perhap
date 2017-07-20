defmodule Perhap.PathsTest do
  use ExUnit.Case, async: true
  import Perhap.Paths

  test "Compiles paths into map" do
    assert collate_paths([{"/a", "A"},
                          {"/a", "A'"},
                          {"/b", "B"}]) == [{"/a", ["A", "A'"]},
                                            { "/b", ["B"]}]
  end
end

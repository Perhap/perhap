defmodule PerhapTest.Router do
  use ExUnit.Case, async: true

  test "makes valid cowboy pathspecs for events" do
    left = {"/c/e/:entity_id/:event_id", PerhapTest.Router, []}
    right = Perhap.Router.make_event_path( %{ context: "c",
                                              event_type: "e",
                                              model: PerhapTest.Router,
                                              opts: [] })
    assert left == right
  end

  test "raises an error with invalid event pathspecs" do
    assert_raise FunctionClauseError, fn ->
      Perhap.Router.make_event_path( %{} )
    end
  end

  test "makes valid cowboy pathspecs for models not single" do
    left = {"/c/d/:entity_id/model", PerhapTest.Router, []}
    right = Perhap.Router.make_model_path( %{ context: "c",
                                              domain: "d",
                                              model: PerhapTest.Router,
                                              opts: [single: false] })
    assert left == right
  end

  test "makes valid cowboy pathspecs for single models" do
    left = {"/c/d/model", PerhapTest.Router, [single: true]}
    right = Perhap.Router.make_model_path( %{ context: "c",
                                              domain: "d",
                                              model: PerhapTest.Router,
                                              opts: [single: true] })
    assert left == right
  end

  test "raises an error with invalid model pathspecs" do
    assert_raise FunctionClauseError, fn ->
      Perhap.Router.make_model_path( %{} )
    end
  end

end

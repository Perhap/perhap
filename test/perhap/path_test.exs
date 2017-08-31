defmodule PerhapTest.Path do
  use ExUnit.Case, async: true

  # Paths

  test "makes valid cowboy pathspecs for events" do
    left = [ {"/c/e/:entity_id/:event_id", Perhap.Router, [model: PerhapTest.Router]},
             {"/c/:event_id", Perhap.Router, []} ]
    right = Perhap.Path.make_event_pathspec( %Perhap.Path.Pathspec{ context: "c",
                                                                        event_type: "e",
                                                                        model: PerhapTest.Router,
                                                                        handler: Perhap.Router,
                                                                        opts: [] })
    assert left == right
  end

  test "raises an error with invalid event pathspecs" do
    assert_raise FunctionClauseError, fn ->
      Perhap.Path.make_event_pathspec( %{} )
    end
  end

  test "makes valid cowboy pathspecs for models not single" do
    left = {"/c/d/:entity_id/model", Perhap.Router, [single: false, model: PerhapTest.Router]}
    right = Perhap.Path.make_model_pathspec( %Perhap.Path.Pathspec{ context: "c",
                                                                        domain: "d",
                                                                        model: PerhapTest.Router,
                                                                        handler: Perhap.Router,
                                                                        opts: [single: false] })
    assert left == right
  end

  test "makes valid cowboy pathspecs for single models" do
    left = {"/c/d/model", Perhap.Router, [model: PerhapTest.Router, single: true]}
    right = Perhap.Path.make_model_pathspec( %Perhap.Path.Pathspec{ context: "c",
                                                                        domain: "d",
                                                                        model: PerhapTest.Router,
                                                                        handler: Perhap.Router,
                                                                        opts: [single: true] })
    assert left == right
  end

  test "raises an error with invalid model pathspecs" do
    assert_raise FunctionClauseError, fn ->
      Perhap.Path.make_model_pathspec( %{} )
    end
  end

  # Rewriting

  test "" do
  end

end

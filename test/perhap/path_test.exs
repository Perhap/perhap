defmodule PerhapTest.Path do
  use ExUnit.Case, async: true

  # Paths

  test "makes valid cowboy pathspecs for events" do
    left = [ {"/c/e/:entity_id/:event_id", Perhap.Handler, [model: PerhapTest.Model]},
             {"/c/:event_id", Perhap.Handler, [model: PerhapTest.Model]} ]
    right = Perhap.Path.make_event_pathspec( %Perhap.Path.Pathspec{ context: "c",
                                                                        event_type: "e",
                                                                        model: PerhapTest.Model,
                                                                        handler: Perhap.Handler,
                                                                        opts: [] })
    assert left == right
  end

  test "raises an error with invalid event pathspecs" do
    assert_raise FunctionClauseError, fn ->
      Perhap.Path.make_event_pathspec( %{} )
    end
  end

  test "makes valid cowboy pathspecs for models not single" do
    left = {"/c/d/:entity_id/model", Perhap.Handler, [single: false, model: PerhapTest.Model]}
    right = Perhap.Path.make_model_pathspec( %Perhap.Path.Pathspec{ context: "c",
                                                                        domain: "d",
                                                                        model: PerhapTest.Model,
                                                                        handler: Perhap.Handler,
                                                                        opts: [single: false] })
    assert left == right
  end

  test "makes valid cowboy pathspecs for single models" do
    left = {"/c/d/model", Perhap.Handler, [model: PerhapTest.Model, single: true]}
    right = Perhap.Path.make_model_pathspec( %Perhap.Path.Pathspec{ context: "c",
                                                                        domain: "d",
                                                                        model: PerhapTest.Model,
                                                                        handler: Perhap.Handler,
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

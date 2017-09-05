defmodule PerhapTest.Path do
  use ExUnit.Case, async: true

  # Paths

  test "makes valid cowboy pathspecs for events" do
    right = {"/c/e/:entity_id/:event_id", Perhap.Handler, [model: PerhapTest.Model]}
    left = Perhap.Path.make_post_event_pathspec( %Perhap.Path.Pathspec{ context: "c",
                                                                         event_type: "e",
                                                                         model: PerhapTest.Model,
                                                                         handler: Perhap.Handler,
                                                                         opts: [] })
    assert left == right
  end

  test "raises an error with invalid event pathspecs" do
    assert_raise FunctionClauseError, fn ->
      Perhap.Path.make_post_event_pathspec( %{} )
    end
  end

  test "makes valid cowboy pathspecs for models not single" do
    right = {"/c/d/:entity_id/model", Perhap.Handler, [single: false, model: PerhapTest.Model]}
    left = Perhap.Path.make_model_pathspec( %Perhap.Path.Pathspec{ context: "c",
                                                                    domain: "d",
                                                                    model: PerhapTest.Model,
                                                                    handler: Perhap.Handler,
                                                                    opts: [single: false] })
    assert left == right
  end

  test "makes valid cowboy pathspecs for single models" do
    right = {"/c/d/model", Perhap.Handler, [single: true, model: {PerhapTest.Model, :single}]}
    left = Perhap.Path.make_model_pathspec( %Perhap.Path.Pathspec{ context: "c",
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

defmodule Perhap.Path do
  require Logger

  defmodule Pathspec do
    @type t :: %__MODULE__{ context: atom(),
                            event_type: atom(),
                            domain: atom(),
                            model: term(),
                            handler: module(),
                            opts: opts
                          }
    @type opts :: [ single: true | false, model: module() ]
    defstruct context: nil, event_type: :none, domain: nil, model: nil, handler: nil, opts: []
  end

  @spec make_post_event_pathspec(Pathspec.t) :: { String.t, module(), Pathspec.opts }
  def make_post_event_pathspec(%Pathspec{ context: context,
                                          event_type: event_type,
                                          model: model,
                                          handler: handler,
                                          opts: opts}) do
    model2 = case Keyword.get(opts, :single) do
      true -> {model, :single}
      _ -> model
    end
    { "/#{context}/#{event_type}/:entity_id/:event_id", handler, Keyword.merge(opts, [model: model2]) }
  end

  @spec make_get_event_pathspec(Pathspec.t) :: { String.t, module(), Pathspec.opts }
  def make_get_event_pathspec(%Pathspec{ context: context,
                                         handler: handler,
                                         opts: opts}) do
     { "/#{context}/:event_id/event", handler, opts }
   end

  @spec make_get_events_pathspec(Pathspec.t) :: list({ String.t, module(), Pathspec.opts })
  def make_get_events_pathspec(%Pathspec{ context: context,
                                         handler: handler,
                                         opts: opts}) do
     [ { "/#{context}/:entity_id/events", handler, opts }, { "/#{context}/events", handler, opts } ]
  end

  @spec make_model_pathspec(Pathspec.t) :: { String.t, module(), Pathspec.opts }
  def make_model_pathspec(%Pathspec{ context: context,
                                     domain: domain,
                                     model: model,
                                     handler: handler,
                                     opts: opts }) do
    case Keyword.get(opts, :single) do
      true ->
        { "/#{context}/#{domain}/model", handler, Keyword.merge(opts, [model: {model, :single}]) }
      _ ->
        { "/#{context}/#{domain}/:entity_id/model", handler, Keyword.merge(opts, [model: model]) }
    end
  end

  def make_route_table(routes) do
    routes |> consolidate_routes |> route_table_from_consolidated
  end

  def consolidate_routes(routes) do
    routes |> Enum.reduce(%{}, fn({path, handler, state}, acc) ->
      case Map.has_key?(acc, path) do
        true ->
          {_, newstate} = acc[path]
          Map.replace(acc, path, {handler, Enum.into(newstate, [model: state[:model]])})
        _ ->
          Map.put(acc, path, {handler, state})
      end
    end )
  end

  def route_table_from_consolidated(croutes) do
    croutes
    |> Map.to_list
    |> Enum.map(fn {path, {handler, state}} -> {path, handler, state} end)
  end

  ## Rewriting routes

end

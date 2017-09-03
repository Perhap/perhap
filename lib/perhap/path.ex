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
    { "/#{context}/#{event_type}/:entity_id/:event_id", handler, Keyword.merge(opts, [model: model]) }
  end

  @spec make_get_event_pathspec(Pathspec.t) :: { String.t, module(), Pathspec.opts }
  def make_get_event_pathspec(%Pathspec{ context: context,
                                         handler: handler,
                                         opts: opts}) do
     { "/#{context}/:event_id/event", handler, opts }
   end

  @spec make_get_events_pathspec(Pathspec.t) :: { String.t, module(), Pathspec.opts }
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
        { "/#{context}/#{domain}/model",
          handler, Keyword.merge(opts, [model: model, single: true]) }
      _ ->
        { "/#{context}/#{domain}/:entity_id/model",
          handler, Keyword.merge(opts, [model: model]) }
    end
  end

  ## Rewriting routes

end

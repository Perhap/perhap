defmodule Perhap.Router do

  # Utilities

  ## Making routes

  def make_event_pathspec(%{ context: context,
                         event_type: event_type,
                         model: model,
                         handler: handler,
                         opts: opts}) do
    { "/#{context}/#{event_type}/:entity_id/:event_id",
      handler, Keyword.merge(opts, [model: model]) }
  end

  def make_model_pathspec(%{ context: context,
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

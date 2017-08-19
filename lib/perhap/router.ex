defmodule Perhap.Router do

  def make_event_path(%{ context: context,
                         event_type: event_type,
                         model: model,
                         opts: opts}) do
    {"/#{context}/#{event_type}/:entity_id/:event_id", model, opts}
  end

  def make_model_path(%{ context: context,
                         domain: domain,
                         model: model,
                         opts: opts }) do
    case Keyword.get(opts, :single) do
      true ->
        {"/#{context}/#{domain}/model", model, [single: true]}
      _ ->
        {"/#{context}/#{domain}/:entity_id/model", model, []}
    end
  end
end

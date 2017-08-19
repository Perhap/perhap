defmodule Perhap.Router do

  def make_event_path(%{ context: context,
                         event_type: event_type,
                         model: model }) do
    {"/#{context}/#{event_type}/:entity_id/:event_id", model, []}
  end

  def make_model_path(%{ context: context,
                         domain: domain,
                         model: model,
                         single: single }) do
    case single do
      true ->
        {"/#{context}/#{domain}/model", model, [single: true]}
      _ ->
        {"/#{context}/#{domain}/:entity_id/model", model, []}
    end
  end
end

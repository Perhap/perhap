defmodule Perhap.ModelHandler do
  use Perhap.Handler

  def handle(:get_model, conn, state) do
    Perhap.Response.send(conn, 200, %{model: get_model(state)})
  end

  def get_model(state) do
    model = state[:model]
    ({model2, _} = child) = case model do
      {model2, :single} -> {model2, :single}
      model2 -> {model2, state[:entity_id]}
    end
    apply(model2, :ensure_started, [child])
    case apply(model2, :retrieve, [child]) do
      {:ok, model} ->
        model
      _ ->
        raise(RuntimeError, message: :not_found)
    end
  end
end

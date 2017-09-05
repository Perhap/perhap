defmodule Perhap.ModelHandler do
  use Perhap.Handler

  def handle(:get_model, conn, state) do
    Perhap.Response.send(conn, 200, %{model: get_model(state)})
  end

  def get_model(state) do
    module = state[:model]
    entity_id = state[:entity_id]
    name = {module, entity_id}
    apply(module, :ensure_started, [name])
    case apply(module, :retrieve, [name]) do
      {:ok, model} ->
        model
      e ->
        raise(RuntimeError, message: :not_found)
    end
  end
end

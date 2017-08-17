defmodule Shopping.Stats.CartsActive do
  alias Perhap.Event
  @behaviour Domain

  @type t :: %__MODULE__{ last_minute: list(Event.UUIDv4.t),
                          last_hour: list(Event.UUIDv4.t),
                          last_day: list(Event.UUIDv4.t)}
  defstruct last_minute: [], last_hour: [], last_day: []

  @type event_type :: ( :cart_was_active
                        | :minute_tick
                        | :hour_tick
                        | :day_tick )
    #     {"/stats/cart_was_active/", %{cart_id: cart_id, timestamp: timestamp}}
  @type event :: %{cart_id: Event.UUIDv4, timestamp: integer()}

  @spec reduce(event_type, t, event) :: { t, list(event) }
  def reduce(event, nil, event_data),
    do: reduce(event, %__MODULE__{}, event_data)
  def reduce(:cart_was_active, model, event_data),
    do: { %{ model | last_minute: [ event_data.cart_id | model.last_minute ] }}
  def reduce(:minute_tick, model, %{ metadata: metadata }) do
    { last_minute, last_hour } = move_on_time(metadata.timestamp, -60_000_000, model.last_minute, model.last_hour)
    { %{ model | last_minute: last_minute, last_hour: last_hour }, [] }
  end
  def reduce(_event, model, _event_data),
    do: { model, [] }

  def move_on_time(_,_,_,_) do
  end

end 

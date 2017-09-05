defmodule Shopping.Stats.CartsActive do

  @type t :: %__MODULE__{ last_minute: list(Perhap.Event.UUIDv4.t),
                          last_hour: list(Perhap.Event.UUIDv4.t),
                          last_day: list(Perhap.Event.UUIDv4.t)}
  defstruct last_minute: [], last_hour: [], last_day: []

  @type event_type :: ( :cart_was_active
                        | :minute_tick
                        | :hour_tick
                        | :day_tick )
    #     {"/stats/cart_was_active/", %{cart_id: cart_id, timestamp: timestamp}}
  @type event :: %{cart_id: Event.UUIDv4, timestamp: integer()}

  @spec reducer(event_type, t, event) :: { t, list(Perhap.Event.t) }
  def reducer(event, nil, event_data),
    do: reducer(event, %__MODULE__{}, event_data)
  def reducer(:cart_was_active, model, event_data),
    do: { %{ model | last_minute: [ event_data.cart_id | model.last_minute ] }}
  def reducer(:minute_tick, model, %{ metadata: metadata }) do
    { last_minute, last_hour } = move_on_time(metadata.timestamp, -60_000_000, model.last_minute, model.last_hour)
    { %{ model | last_minute: last_minute, last_hour: last_hour }, [] }
  end
  def reducer(_event, model, _event_data),
    do: { model, [] }

  def move_on_time(_,_,_,_) do
  end

end 

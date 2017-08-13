defmodule Shopping.Stats.CartsActive do
  use Perhap.Domain

  @type t :: %Shopping.Stats.CartsActive{last_minute :: list(uuidv4),
                                         last_hour :: list(uuidv4),
                                         last_day :: list(uuidv4)}
  defstruct last_minute: [], last_hour: [], last_day: []

  @type event:: ( :cart_was_active, :minute_tick, :hour_tick, :day_tick )
  @type event_data :: %{metadata: Perhap.Domain.Metadata, data: map}

  @spec reducer(event, t, event_data) :: {t, list(Perhap.Domain.Event)}
  def reducer(event, nil, event_data),
    do: reducer(event, %Shopping.Stats.CartsActive{}, event_data)
  def reducer(:cart_was_active, model, event_data),
    do: { %{ model | last_minute: [ event_data.cart_id | model.last_minute ]
  def reducer(:minute_tick, model, %{ metadata: metadata }) do
    { last_minute, last_hour } = move_on_time(metadata.timestamp, -60_000_000, model.last_minute, model.last_hour)
    { %{ model | model.last_minute: last_minute, model.last_hour: last_hour }, [] }
  end
  def reducer(_event, model, _event_data),
    do: { model, [] }

  def move_on_time(timestamp, offset, [], to),
    do: { [], to }
  def move_on_time(timestamp, offset, [ head | tail ], to),
    when: head.timestamp < (timestamp - offset)
    do: 

end 

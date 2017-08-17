defmodule Shopping.Cart do
  alias Perhap.Event, as: Event
  @behaviour Domain

  @type t :: %__MODULE__{ id: String.t, items: list(any), total: number() }
  defstruct [:id, items: [], total: 0.00]

  @type event_type :: ( :cart_add
                        | :cart_remove
                        | :cart_emptied
                        | :checkout_start
                        | :checkout_finish )
  @type event :: %{ type: event_type, item: String.t, quantity: number(), price: number() }

  @spec reduce(event_type, __MODULE__.t, event) :: { __MODULE__.t, list(event) }
  def reduce(event, nil, event_data),
    do: reduce(event,
                %Shopping.Cart{id: event_data.metadata.id, items: []},
                event_data)
  def reduce(:cart_add, model, %{data: data}) do
    model = %{model | items: ( model.item
                               |> add_item(make_item(data.item)) )}
    case empty_cart?(model) do
      true -> { model,
                [ { "/stats/cart_emptied",
                    %{ id: model.id, timestamp: Event.timestamp() } }]}
      _ -> { model, [] }
    end
  end
  def reduce(:cart_remove, model, %{data: data}),
    do: { %{model | items: (model.items |> remove_item(make_item(data.item)) )}, [] }
  def reduce(:cart_emptied, model, _event_data),
    do: { %{model | items: [] }, [] }
  def reduce(:checkout_start, model, _event_data),
    do: { model, [] }
  def reduce(:checkout_finish, model, _event_data),
    do: { %{model | items: [] }, [] }
  def reduce(_event, model, _event_data),
    do: { model, [] }

  defp make_item(data) do
    %{product_id: data.product_id,
      product_name: data.product_name,
      quantity: data.quantity,
      price: data.price}
  end

  defp add_item(items, item),
    do: adjust_quantity(items, item, :+)
  defp remove_item(items, item),
    do: adjust_quantity(items, item, :-)

  defp adjust_quantity(items, item, func) do
    #do: adjust_quantity(items, item, [], func)
    # items
    # |> Enum.reduce_while( [], fn cart_item, acc ->
      #                             if cart_item.product_id == item.product_id
      #                             and cart_item.price == item.price do
        #                               adjusted_item = %{ cart_item | apply(Kernel, func, [cart_item.quantity, item.quantity]) }
        #                             { :halt, Enum.reverse(acc) ++ [ adjusted_item ] ++ cart }
        #                           else
          #                             { :cont, [ cart_item | acc ] }
          #                         end)

  end

  defp empty_cart?(model), do: model.items == []

end

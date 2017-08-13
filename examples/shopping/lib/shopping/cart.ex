defmodule Shopping.Cart do
  use Perhap.Domain

  @type item :: %{product_id: uuidv4, product_name: String.t, quantity: number, price: number}
  @type t :: %Shopping.Cart{id :: uuidv4, items :: list(item)}
  defstruct [:cart_id, items: []]

  @type event:: ( :cart_add | :cart_remove | :checkout_start | :checkout_finish )
  @type event_data :: %{metadata: Perhap.Domain.Metadata, data: map}

  @spec reducer(event, t, event_data) :: {t, list(Perhap.Domain.Event)}
  def reducer(event, nil, event_data),
    do: reducer(event,
                %Shopping.Cart{id: event_data.metadata.id, items: []},
                event_data)
  def reducer(:cart_add, model, %{data: data}) do
    model = %{model | items: ( model.item
                               |> add_item(make_item(data.item)) )}
    case empty_cart?(model) do
      true -> { model,
                [ { "/stats/cart_emptied",
                    %{ cart_id: model.cart_id, timestamp: timestamp() } }]}
      _ -> { model, [] }
    end
  end
  def reducer(:cart_remove, model, %{data: data}),
    do: { %{model | items: (model.items |> remove_item(make_item(data.item)) )}, [] }
  def reducer(:cart_emptied, model, _event_data),
    do: { %{model | items: [] }, [] }
  def reducer(:checkout_start, model, _event_data),
    do: { model, [] }
  end
  def reducer(:checkout_finish, model, _event_data),
    do: { %{model | items: [] }, [] }
  def reducer(_event, model, _event_data),
    do: { model, [] }

  defp make_item(data) d%{data: data}
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
    items
    |> Enum.reduce_while( [], fn cart_item, acc ->
                                if cart_item.product_id == item.product_id
                                  and cart_item.price == item.price do
                                    adjusted_item = %{ cart_item | apply(Kernel, func, [cart_item.quantity, item.quantity]) }
                                    { :halt, Enum.reverse(acc) ++ [ adjusted_item ] ++ cart }
                                  else
                                    { :cont, [ cart_item | acc ] }
                                  end)

  end

  defp empty_cart?(model), do: model.items == []

end

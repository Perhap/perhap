defmodule Shopping.Cart do
  use Perhap.Domain

  @type t :: %__MODULE__{ id: String.t, items: list(any), total: number() }
  defstruct [:id, items: [], total: 0.00]

  @type event_type :: ( :item_added
                        | :item_removed
                        | :cart_emptied
                        | :checkout_started
                        | :checkout_finished )
  @type event_data :: %{ item: String.t, quantity: number(), price: number() }

  #@initial_state %__MODULE__{id: "", items: []}
  @initial_state %{}

  @spec reducer(event_type, t, Perhap.Event.t) :: { t, list(Perhap.Event.t) }
  def reducer(:item_added, model, %{data: event_data}) do
    model2 = %{model | items: ( model.item
                               |> add_item(make_item(event_data.item)) )}
    {model2, []}
  end
  def reducer(:item_removed, model, %{data: event_data} = _event_data) do
    { %{model | items: (model.items |> remove_item(make_item(event_data.item)) )}, [] }
    case empty_cart?(model) do
      true -> { model,
                [ { "/stats/cart_emptied",
                    %{ id: model.id, timestamp: Perhap.Event.timestamp() } }]}
      _ -> { model, [] }
    end
  end
  def reducer(:cart_emptied, model, _event_data), do: empty_cart(model)
  def reducer(:checkout_started, model, _event_data), do: { model, [] }
  def reducer(:checkout_finished, model, _event_data), do: empty_cart(model)

  defp empty_cart(model), do: { %{model | items: [] }, [] }

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

  defp adjust_quantity(_items, _item, _func) do
    #do: adjust_quantity(items, item, [], func)
    # items
    # |> Enum.reducer_while( [], fn cart_item, acc ->
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

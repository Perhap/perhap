defmodule Shopping.Cart do
  use Perhap.Domain

  @type t :: [id: Perhap.Event.UUIDv4.t, items: map(), total: number()]
  @type items :: %{required(Perhap.Event.UUIDv4.t) =>
    %{item: String.t, quantity: number(), price: number()}}
  defstruct id: nil, items: %{}, total: 0.00

  @type event_type :: :item_added | :item_removed
  @type event_data :: %{ "item_id": Perhap.Event.UUIDv4.t,
                         "item": String.t,
                         "quantity": number(),
                         "price": number() }

  def reducer(:item_added, model, %{data: event_data, metadata: metadata}) do
    cart1 = %__MODULE__{model | id: metadata.entity_id, items: model.items |> add_item(event_data)}
    cart2 = %__MODULE__{cart1 | total: cart1.items |> calculate_total}
    {cart2, []}
  end

  def add_item(items, event) do
    items
    |> Map.update(event["item_id"],
         %{item: event["item"], quantity: event["quantity"], price: event["price"]},
         fn(item)-> %{item | quantity: item.quantity + event["quantity"], price: event["price"]} end)
  end

  def calculate_total(items) do
    items
    |> Map.values
    |> Enum.reduce(0, fn(%{quantity: q, price: p}, acc) -> acc + q * p end)
  end
end

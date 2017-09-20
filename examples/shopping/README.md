# Shopping

## Presentation notes

`mix new shopping`

In `mix.exs`:

```
  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:perhap],
      extra_applications: [:logger],
      mod: {Shopping, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:perhap, path: "~/Development/Perhap/perhap"}
    ]
  end
end
```

In `config/config.exs`:

```
use Mix.Config

config :perhap,
  port: 9000

config :logger,
  backends: [:console],
  compile_time_purge_level: :info,
  level: :warn

config :swarm,
  sync_nodes_timeout: 10 # prevent a delay while it looks for more nodes
```

### lib/shopping.ex

```
defmodule Shopping do
  use Perhap, app: :shopping

  context :store,
    cart: [model: Shopping.Cart,
           events: [:item_added, :item_removed]]
end
```

`mix deps.get`

`mix test`

### lib/shopping/cart.ex

`mkdir lib/shopping test/shopping`

`rm test/shopping_test.exs`

```
defmodule ShoppingTest.Cart do
  use ExUnit.Case, async: true

  test "handles an added item" do
    product = %{"item_id" => Perhap.Event.get_uuid_v4(), "item" => "testable", "quantity" => 1, "price" => 0.99}
    event = %{data: product, metadata: %{entity_id: Perhap.Event.get_uuid_v4()}}
    {cart, []} = Shopping.Cart.reducer(:item_added, %Shopping.Cart{}, event)
    assert cart.items ==
      %{product["item_id"] => %{ item: product["item"], quantity: product["quantity"], price: product["price"]}}
  end

  test "calculates the price" do
    product1 = %{"item_id" => Perhap.Event.get_uuid_v4(), "item" => "testable", "quantity" => 2, "price" => 0.99}
    event1 = %{data: product1, metadata: %{entity_id: Perhap.Event.get_uuid_v4()}}
    product2 = %{"item_id" => Perhap.Event.get_uuid_v4(), "item" => "testable2", "quantity" => 3, "price" => 0.69}
    event2 = %{data: product2, metadata: %{entity_id: Perhap.Event.get_uuid_v4()}}
    {cart1, []} = Shopping.Cart.reducer(:item_added, %Shopping.Cart{}, event1)
    assert cart1.total == 2 * 0.99
    {cart2, []} = Shopping.Cart.reducer(:item_added, cart1, event2)
    assert cart2.total == 2 * 0.99 + 3 * 0.69
  end
end
```

```
defmodule Shopping.Cart do
  use Perhap.Domain

  @type t :: [id: Perhap.Event.UUIDv4.t, items: list(items), total: number()]
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
```

### Demo from iex

```
> Shopping.start
Starting Cowboy listener for Elixir.Shopping on http://127.0.0.1:9000.
{:ok, #PID<0.287.0>}

> product1 = %{ "item_id" => Perhap.Event.get_uuid_v4(), "item" => "testable", "quantity" => 2, "price" => 0.99 }

> event = %{context: :store, event_type: :item_added, entity_id: Perhap.Event.get_uuid_v4(), event_id: Perhap.Event.get_uuid_v1(), data: product1}
  event_id: "bb60045e-922e-11e7-8f88-f1320000011f", event_type: :item_added}
%{context: :store,
  data: %{"item" => "testable",
    "item_id" => "aacdfc04-166d-44e3-988d-2981339fd6c1", "price" => 0.99,
    "quantity" => 2}, entity_id: "004c389b-0b54-4435-bb16-9097ca108817",
  event_id: "350bfd06-9231-11e7-9aab-f13100000107", event_type: :item_added}

> Shopping.event event
:ok

> Shopping.model(:store, :cart, event.entity_id)
%Shopping.Cart{id: nil,
 items: %{"aacdfc04-166d-44e3-988d-2981339fd6c1" => %{item: "testable",
     price: 0.99, quantity: 2}}, total: 1.98}
```

### Demo from bash

```
curl -X POST http://localhost:9000/store/item_added/f2f47a95-fb61-4c5a-a83e-7a92210b09bb/3307faba-925d-11e7-8383-f132000000f5 -d "{\"quantity\":1,\"price\":31.99,\"item_id\":\"a308b1c2-ca65-47dd-a031-a3b8d3afafd4\",\"item\":\"Elephant snacks\"}"
curl -X POST http://localhost:9000/store/item_added/f2f47a95-fb61-4c5a-a83e-7a92210b09bb/570b7e1e-926c-11e7-850b-f132000000f5 -d "{\"quantity\":2,\"price\":8.79,\"item_id\":\"54b12494-2dfa-487a-aedb-0a7769bb620f\",\"item\":\"Toothbrush (Elephant)\"}"
curl -X POST http://localhost:9000/store/item_added/f2f47a95-fb61-4c5a-a83e-7a92210b09bb/bb1dd6b8-926c-11e7-9ade-f132000000f5 -d "{\"quantity\":2,\"price\":23.31,\"item_id\":\"deed1ee5-59d9-4fcd-a581-50df6585e002\",\"item\":\"Pachyderm leash\"}"
curl -X GET http://localhost:9000/store/cart/f2f47a95-fb61-4c5a-a83e-7a92210b09bb/model | json_pp
```

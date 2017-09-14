defmodule Shopping do
  use Perhap, app: :shopping

  context :store,
    cart: [model: Shopping.Cart,
           events: [:item_added, :item_removed]]
end

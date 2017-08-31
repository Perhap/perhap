defmodule Shopping do
  @moduledoc """
  Documentation for Shopping.

  Interesting statistics:
  * Active carts last minute last hour last day
  * Age of carts mean 90th 99th

  """

  use Perhap, app: :shopping

  context :store,
    cart: [
      model: Shopping.Cart,
      events: [:item_added,
               :item_removed,
               :cart_emptied,
               :checkout_started,
               :checkout_finished]
    ]

  context :stats,
    carts_active: [
      single: Shopping.Stats.CartsActive,
      events: [:cart_was_active, :minute_tick]
    ],
    carts_age: [
      single: Shopping.Stats.CartAge,
      events: [:cart_created, :cart_emptied]
    ]

    # rewrite_event "/store/item_*/:cart_id",
    #   {"/stats/cart_was_active/", %{cart_id: cart_id, timestamp: timestamp}}
    #   rewrite_event "/store/checkout_started/:cart_id",
    #     {"/stats/cart_was_active/", %{cart_id: cart_id, timestamp: timestamp}}
    #   rewrite_event "/store/checkout_finished/:cart_id",
    #     {"/stats/cart_emptied/", %{cart_id: cart_id, timestamp: timestamp}}
    #
    # tick "/stats/minute_tick", every: [:minute]
    #   tick "/stats/hour_tick", every: [:hour]
    #   tick "/stats/day_tick", every: [:day]

end

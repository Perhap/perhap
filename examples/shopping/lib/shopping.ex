defmodule Shopping do
  @moduledoc """
  Documentation for Shopping.

  Interesting statistics:
  * Active carts last minute last hour last day
  * Age of carts mean 90th 99th

  """

  use Perhap, app: :shopping

  context "store" do
    domain "cart",
      model: Shopping.Cart,
      events: [:product_added,
               :product_removed,
               :cart_emptied,
               :checkout_started,
               :checkout_finished]
  end

  context "stats" do
    domain "carts_active",
      single: Shopping.Stats.CartsActive,
      events: [:cart_was_active, :minute_tick],
    domain "carts_age",
      single: Shopping.Stats.CartAge,
      events: [:cart_created, :cart_emptied]
  end

  rewrite_event "/store/product_*/:cart_id" do
    {"/stats/cart_was_active/", %{cart_id: cart_id, timestamp: timestamp}},
  end
  rewrite_event "/store/checkout_started/:cart_id" do
    {"/stats/cart_was_active/", %{cart_id: cart_id, timestamp: timestamp}}
  end
  rewrite_event "/store/checkout_finished/:cart_id" do
    {"/stats/cart_emptied/", %{cart_id: cart_id, timestamp: timestamp}}
  end

  tick "/stats/minute_tick", every: [:minute]
  tick "/stats/hour_tick", every: [:hour]
  tick "/stats/day_tick", every: [:day]

end

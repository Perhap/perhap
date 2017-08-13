defmodule PerhapTest.Fixture do
  import Perhap
  use Perhap, app: :perhap_test

  context :two,
    mine: [
      single: "me",
      events: [:none]
    ],
    ours: [
      model: "us",
      events: [:none]
    ]
end

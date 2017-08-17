defmodule PerhapTest.Fixture do
  import Perhap
  use Perhap, app: :perhap_test

  context :two,
    mine: [
      single: PerhapTest.Fixture.Mine,
      events: [:an_event_type]
    ],
    ours: [
      model: PerhapTest.Fixture.Ours,
      events: [:an_event_type, :another_event_type]
    ]
end

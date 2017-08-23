defmodule PerhapTest.Fixture do
  import Perhap
  use Perhap, app: :perhap_test, port: 4499, bind: "127.0.0.1"

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

defmodule PerhapTest.DomainService do
  use Perhap.Domain
end

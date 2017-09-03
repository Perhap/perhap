defmodule Fixture do
  import Perhap
  use Perhap, app: :fixture, port: 4499

  context :test,
    domain1: [
      single: Fixture.Domain1,
      events: [:domain1event]
    ],
    domain2: [
      model: Fixture.Domain2,
      events: [:domain2event1, :domain2event2]
    ]
end

defmodule Fixture.Domain1 do
  use Perhap.Domain
  @initial_state 0

  def reducer(_event_type, model, _event) do
    {model + 1, []}
  end
end

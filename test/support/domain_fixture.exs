defmodule DomainFixture do
  import Perhap
  use Perhap, app: :domain_fixture, port: 4498

  context :test,
    domain1: [
      single: DomainFixture.Domain1,
      events: [:domain1event]
    ],
    domain2: [
      model: DomainFixture.Domain2,
      events: [:domain2event1, :domain2event2]
    ]
end

defmodule DomainFixture.Domain1 do
  use Perhap.Domain
  @initial_state 0

  def reducer(_event_type, model, _event) do
    {model + 1, []}
  end
end

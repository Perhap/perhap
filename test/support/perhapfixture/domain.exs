defmodule PerhapFixture.Domain do
  import Perhap
  use Perhap, app: :perhap_test, port: 4498, bind: "127.0.0.1"

  context :test,
    domain1: [
      single: PerhapFixture.Domain.Domain1,
      events: [:domain1event]
    ],
    domain2: [
      model: PerhapFixture.Domain.Domain2,
      events: [:domain2event1, :domain2event2]
    ]
end

defmodule PerhapFixture.Domain.Domain1 do
  use Perhap.Domain
  @initial_state 0

  def reducer(_event_type, model, _event) do
    {model + 1, []}
  end
end

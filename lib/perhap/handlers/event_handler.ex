defmodule Perhap.EventHandler do
  use Perhap.Handler


  # event_posted |> save_event |> respond_to_event |> dispatch_event |> save_model |> clean_up

  def handle("GET", conn, state) do
    {:ok, conn |> event_requested(state), state}
  end
  def handle("POST", conn, state) do
    # Todo: not correct!
    conn2 = conn |> event_posted(state) |> save_event |> respond_to_event
    Perhap.Dispatcher.dispatch({state[:model], :something}, :event, :opts)
    {:ok, conn2, state}
  end

  @spec event_requested(:cowboy_req.req(), any()) :: :cowboy_req.req()
  def event_requested(conn, _state) do
    Perhap.Response.send(conn, Perhap.Error.make(:operation_not_implemented))
    # Todo: get_event_from_store
  end

  @spec event_posted(:cowboy_req.req(), any()) ::
    {:ok, :cowboy_req.req(), String.t} | {:error, :cowboy_req.req(), atom()}
  def event_posted(conn, _state) do
    case read_body(conn) do
      {:ok, conn2, body} -> {:ok, conn2, body}
      {:timeout, conn2, _body} ->  {:error, conn2, :request_timeout}
    end
  end

  def save_event({:ok, conn, body}) do
    save_event_to_db(conn, body)
  end
  def save_event(error = {:error, _conn, reason}) do
    Logger.error("[perhap] Unable to read event from body: #{inspect(reason)}")
    error
  end

  def respond_to_event(ok = {:ok, conn, _event}) do
    Perhap.Response.send(conn, 204)
    ok
  end
  def respond_to_event({:error, conn, reason}) do
    Perhap.Response.send(conn, Perhap.Error.make(reason))
    {:error, reason}
  end

  def dispatch_event({:ok, _conn, _event}) do
      #GenServer.cast({EventCoordinator, Enum.at(nodes, node)}, {:notify, event})
      #call not cast
  end
  def dispatch_event(error = {:error, _reason}), do: error

  def save_model({:ok, _model}) do
    # persist to model store
  end
  def save_model({:error, _}) do
  end

  def clean_up({:ok, _model}), do: Logger.debug("[perhap] Saved model to model store")
  def clean_up({:error, reason}), do: Logger.error("[perhap] Unable to save model to model store: #{reason}")


  defp read_body(conn), do: read_body(conn, "")
	defp read_body(conn, acc) do
		read_body_opts = %{ length: @read_length, period: @timeout }
		try do
			case :cowboy_req.read_body(conn, read_body_opts) do
				{:ok, data, conn2} -> {:ok, conn2, acc <> data};
				{:more, data, conn2} -> read_body(conn2, acc <> data)
			end
		catch
			:exit, _ -> {:timeout, conn, acc}
		end
	end

	defp save_event_to_db(conn, body) do
    case Perhap.Event.save(%Perhap.Event{ event_id: get_req(conn, :event_id),
                                          data: get_event_data(body),
                                          metadata: get_event_metadata(conn) }) do
			%Perhap.Event{} = event -> {:ok, conn, event}
      {:error, reason} ->
        Logger.error("[perhap] Unable to save event to db: #{reason}")
        {:error, conn, :service_unavailable}
		end
	end

  defp get_event_data(body) do
		Poison.decode!(body)
  end

  defp get_event_metadata(conn) do
    %Perhap.Event.Metadata{ event_id: get_req(conn, :event_id),
                            entity_id: get_req(conn, :entity_id),
                            scheme: get_req(conn, :scheme),
                            host: get_req(conn, :host),
                            port: get_req(conn, :port),
                            path: get_req(conn, :path),
                            context: get_req(conn, :context),
                            type: get_req(conn, :event_type),
                            user_id: get_req(conn, :user_id),
                            ip_addr: get_req(conn, :remote_ip),
                            timestamp: Perhap.Event.timestamp() }
  end

  defp get_req(conn, :event_id) do
    :cowboy_req.binding(:event_id, conn)
  end
  defp get_req(conn, :entity_id) do
    :cowboy_req.binding(:entity_id, conn)
  end
  defp get_req(conn, :scheme) do
    :cowboy_req.scheme(conn)
  end
  defp get_req(conn, :host) do
    :cowboy_req.host(conn)
  end
  defp get_req(conn, :port) do
    :cowboy_req.port(conn)
  end
  defp get_req(conn, :path) do
    :cowboy_req.path(conn)
  end
  defp get_req(conn, :context) do
    [ context | _rest ] = get_req(conn, :path) |> String.split("/")
    context
  end
  defp get_req(conn, :event_type) do
    [ _context | [ event_type | _rest ] ] = get_req(conn, :path) |> String.split("/")
    event_type
  end
  defp get_req(_conn, :user_id) do
    :none
  end
  defp get_req(conn, :remote_ip) do
    {remote_ip, _remote_port} = :cowboy_req.peer(conn)
		remote_ip |> Tuple.to_list |> Enum.join(".")
  end

end

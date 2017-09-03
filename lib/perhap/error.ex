defmodule Perhap.Error do
  @enforce_keys [:http_code, :code, :message]

  @type t :: %Perhap.Error {
    http_code: ( 400 | 404 | 408 | 413 | 500 | 503 ),
    code:      String.t,
    message:   String.t
  }
  defstruct [:http_code, :code, :message]

  @spec build_error(integer(), String.t, String.t) :: Perhap.Error.t
  defp build_error(http_code, code, message) do
    %Perhap.Error{http_code: http_code, code: code, message: message}
  end

  @spec make(atom) :: Perhap.Error.t
  def make(:invalid_id) do
    build_error(400,
        "InvalidId",
        "V1(event)/V4(entity) UUID Required")
  end

  def make(:validation) do
    build_error(400,
        "ValidationError",
        "One or more required parameter values were missing.")
  end

  def make(:not_found) do
    build_error(404,
        "NotFound",
        "Resource Not Found")
  end

  def make(:request_timeout) do
    build_error(408,
        "RequestTimeout",
        "Please Try Again.")
  end

  def make(:request_too_large) do
    build_error(413,
        "RequestEntityTooLarge",
        "Please send < 1 MB.")
  end

  def make(:model_not_implemented) do
    build_error(500,
        "InternalServerError",
        "Model Not Implemented.")
  end

  def make(:operation_not_implemented) do
    build_error(500,
        "InternalServerError",
        "Operation Not Implemented.")
  end

  def make(:service_unavailable) do
    build_error(503,
        "ServiceUnavailable",
        "Please try again later.")
  end

  def make(any) do
    build_error(503,
        "ServiceUnavailable",
        inspect(any))
  end

  @spec format(atom) :: iodata
  def format(atom) when is_atom(atom) do
    error = make(atom)
    Poison.encode!(%{
      type: error.code,
      message: error.message})
  end

  @spec format(Perhap.Error.t) :: iodata
  def format(%Perhap.Error{} = error) do
    %{type: error.code,
      message: error.message}
  end
end

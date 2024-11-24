defmodule CmbcWeb.LilDBController do
  use CmbcWeb, :controller
  alias CmbcWeb.Errors
  alias Cmbc.CommandParser, as: Command

  def listener(conn, _params) do
    {:ok, body, connection} = Plug.Conn.read_body(conn)

    try do
      with user <- validate_header(connection) do
        {:ok, command} = Command.parse(body)
        {:ok, result} = handle_command(command, user)

        connection
        |> put_resp_content_type("text/plain")
        |> send_resp(200, result)
      end
    rescue
      e ->
        connection
        |> put_resp_content_type("text/plain")
        |> send_resp(400, "Error: " <> Exception.message(e))
    end
  end

  defp validate_header(conn) do
    user = Plug.Conn.get_req_header(conn, "x-client-name")

    if Enum.empty?(user) do
      raise Errors.InvalidHeaderError
    end

    user
  end

  defp handle_command(["SET", key, value], user) when value != "NIL",
    do: handle_set(key, value, user)

  defp handle_command(["SET", _key, value], _) when value == "NIL",
    do: raise(Errors.ValueIsNilError)

  defp handle_command(["SET", _key], _),
    do: raise(Errors.SetSyntaxError)

  defp handle_command(["SET"], _),
    do: raise(Errors.SetSyntaxError)

  defp handle_command(["GET", key], user), do: handle_get(key, user)

  defp handle_command(["GET", _key | _rest], _),
    do: raise(Errors.GetSyntaxError)

  defp handle_command(["GET"], _), do: raise(Errors.GetSyntaxError)

  defp handle_command(["BEGIN"], user), do: handle_begin(user)

  defp handle_command(["BEGIN" | _rest], _),
    do: raise(Errors.BeginSyntaxError)

  defp handle_command(["ROLLBACK"], user), do: handle_rollback(user)

  defp handle_command(["ROLLBACK" | _rest], _),
    do: raise(Errors.RollbackSyntaxError)

  defp handle_command(["COMMIT"], user), do: handle_commit(user)

  defp handle_command(["COMMIT" | _rest], _),
    do: raise(Errors.CommitSyntaxError)

  defp handle_begin(user) do
    try do
      Cmbc.TransactionManager.begin_transaction(user)
    rescue
      _ -> raise Errors.TransactionAlreadyActiveError
    end
  end

  defp handle_get(key, user) do
    # first, check if the user has transaction active.
    # if it does, get the value from the transaction.
    # if it does not, get the value from the db.
    Cmbc.TransactionManager.get_transaction(key, user)
  end

  defp handle_set(key, value, user) do
    Cmbc.TransactionManager.set_transaction(key, value, user)
  end

  defp handle_rollback(user) do
    try do
      Cmbc.TransactionManager.rollback_transaction(user)
    rescue
      _ -> raise Errors.TransactionInactiveError
    end
  end

  defp handle_commit(user) do
    try do
      Cmbc.TransactionManager.commit_transaction(user)
    rescue
      e -> raise e
    end
  end
end

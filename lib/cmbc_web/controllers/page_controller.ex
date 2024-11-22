defmodule CmbcWeb.PageController do
  use CmbcWeb, :controller
  @commands ~w(GET SET BEGIN ROLLBACK COMMIT)

  # This will be the main listener.
  # It will receive commands like 'SET ABC 1'
  # and return the response.
  def listener(conn, _params) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    cmd_key_val = validate_args(body)

    # if the request doesnt have a x-client-name header, return an error.
    if Enum.empty?(Plug.Conn.get_req_header(conn, "x-client-name")) do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(400, "Error: x-client-name header not found")
    end

    user = Plug.Conn.get_req_header(conn, "x-client-name")

    response =
      case cmd_key_val do
        {:error, error_message} ->
          {:error, error_message}

        {:ok, command} ->
          handle_command(command, user)
      end

    case response do
      {:ok, result} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, result)

      {:error, error_message} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(400, "Error: " <> error_message)
    end
  end

  defp validate_args(input) do
    # first, split the args in its spaces.
    # then, if the first element starts with a double quote, it either ends with a double quote or the next element ends with a double quote.
    # the key is valid. and the final part, the value:
    # if the first value element starts with a double quote, it either ends with a double quote or the next element ends with a double quote.

    regex =
      ~r/^(?<command>[A-Z]+)\s*(?<key>[^"]\S*|"(?:\\"|[^"])*")?\s*(?<value>([^"]\S*|"(?:\\"|[^"])*")?)?$/


    case Regex.named_captures(regex, input) do
      %{"command" => command, "key" => "", "value" => ""} when command in @commands ->
        {:ok, [command]}

      %{"command" => command, "key" => key, "value" => ""} when command in @commands ->
        {:ok, [command, key]}

      %{"command" => command, "key" => key, "value" => value} when command in @commands ->
        {:ok, [command, key, value]}

      _ ->
        {:error, "Invalid command format"}
    end
  end

  defp handle_command(["SET", key, value], user) when value != "NIL",
    do: handle_set(key, value, user)

  defp handle_command(["SET", _key, value], _) when value == "NIL",
    do: {:error, "Cannot set a key to NIL"}

  defp handle_command(["SET", _key], _),
    do: {:error, "SET Syntax error - Correct syntax: SET \<key\> \<value\>"}

  defp handle_command(["SET"], _),
    do: {:error, "SET Syntax error - Correct syntax: SET \<key\> \<value\>"}

  defp handle_command(["SET", key, _value], _) when not is_binary(key),
    do: {:error, "Key must be a string"}

  defp handle_command(["GET", key], user) when is_binary(key), do: handle_get(key, user)

  defp handle_command(["GET", key], _) when not is_binary(key),
    do: {:error, "Key must be a string"}

  defp handle_command(["GET", _key | _rest], _),
    do: {:error, "GET Syntax error - Correct syntax: GET \<key\>"}

  defp handle_command(["GET"], _), do: {:error, "GET Syntax error - Correct syntax: GET \<key\>"}

  defp handle_command(["BEGIN"], user), do: handle_begin(user)

  defp handle_command(["BEGIN" | _rest], _),
    do: {:error, "BEGIN Syntax error - Correct syntax: BEGIN"}

  defp handle_command(["ROLLBACK"], user), do: handle_rollback(user)

  defp handle_command(["ROLLBACK" | _rest], _),
    do: {:error, "ROLLBACK Syntax error - Correct syntax: ROLLBACK"}

  defp handle_command(["COMMIT"], user), do: handle_commit(user)

  defp handle_command(["COMMIT" | _rest], _),
    do: {:error, "COMMIT Syntax error - Correct syntax: COMMIT"}

  defp handle_begin(user) do
    case Cmbc.TransactionManager.begin_transaction(user) do
      :ok -> {:ok, "BEGIN"}
      {:error, error_message} -> {:error, error_message}
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
    Cmbc.TransactionManager.rollback_transaction(user)
  end

  defp handle_commit(user) do
    Cmbc.TransactionManager.commit_transaction(user)
  end

end

defmodule CmbcWeb.PageController do
  use CmbcWeb, :controller
  @commands ~w(GET SET BEGIN ROLLBACK COMMIT)

  # This will be the main listener.
  # It will receive commands like 'SET ABC 1'
  # and return the response.
  def listener(conn, _params) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    IO.inspect(Plug.Conn.get_req_header(conn, "x-client-name"))


    cmd_key_val = validate_args(body)
    IO.inspect(cmd_key_val)
    response = case cmd_key_val do
      {:error, error_message} ->
        {:error, error_message}
      {:ok, command} ->
        handle_command(command)
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
    regex = ~r/^(?<command>[A-Z]+)\s+(?<key>[^"]\S*|"(?:\\"|[^"])*")\s*(?<value>([^"]\S*|"(?:\\"|[^"])*")?)?$/
    IO.inspect(Regex.named_captures(regex, input))
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

  defp sanitize(nil), do: nil
  defp sanitize(str) when is_binary(str) do
    case String.starts_with?(str, "\"") and String.ends_with?(str, "\"") do
      true ->
        str
        |> String.slice(1..-2//1)
        |> String.replace("\\\"", "\"") # Unescape quotes
      false -> str
    end
  end

  defp handle_command(["SET", key, value]) when value != "NIL", do: handle_set(key, value)
  defp handle_command(["SET", _key, value]) when value == "NIL", do: {:error, "Cannot set a key to NIL"}
  defp handle_command(["SET", _key]), do: {:error, "SET Syntax error - Correct syntax: SET \<key\> \<value\>"}
  defp handle_command(["SET"]), do: {:error, "SET Syntax error - Correct syntax: SET \<key\> \<value\>"}
  defp handle_command(["SET", key, _value]) when not is_binary(key), do: {:error, "Key must be a string"}

  defp handle_command(["GET", key]) when is_binary(key), do: handle_get(key)
  defp handle_command(["GET", key]) when not is_binary(key), do: {:error, "Key must be a string"}
  defp handle_command(["GET", _key | _rest]), do: {:error, "GET Syntax error - Correct syntax: GET \<key\>"}
  defp handle_command(["GET"]), do: {:error, "GET Syntax error - Correct syntax: GET \<key\>"}

  defp handle_command(["BEGIN"]), do: {:ok, "BEGIN"}

  defp handle_command(["ROLLBACK"]), do: {:ok, "ROLLBACK"}

  defp handle_command(["COMMIT"]), do: {:ok, "COMMIT"}

  defp handle_get(key) do
    case Cmbc.LittleDB.get(key) do
      {:ok, value} ->
        {:ok, value}
      {:error, error_message} ->
        {:error, error_message}
    end
  end

  defp handle_set(key, value) do
    case Cmbc.LittleDB.set(key, value) do
      {:ok, old, new} -> {:ok, old <> " " <> new}
      {:error, error_message} -> {:error, error_message}
    end
  end
end

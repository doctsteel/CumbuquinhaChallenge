defmodule Cmbc.CommandParser do

  alias CmbcWeb.Errors, as: Errors
  @commands ~w(GET SET BEGIN ROLLBACK COMMIT)

  def parse(input) do
    regex =
      ~r/^(?<command>[A-Z]+)\s*(?<key>[^"]\S*|"(?:\\"|[^"])*")?\s*(?<value>([^"]\S*|"(?:\\"|[^"])*")?)?$/

    case Regex.named_captures(regex, String.trim(input)) do
      %{"command" => command, "key" => "", "value" => ""} when command in @commands ->
        {:ok, [command]}

      %{"command" => command, "key" => key, "value" => value} when command in @commands ->
        if not String.match?(key, ~r/^\d+$/) and key != "TRUE" and key != "FALSE" do
          case value do
            "" -> {:ok, [command, key]}
            _ -> {:ok, [command, key, value]}
          end
        else
          raise Errors.KeyNotStringError, key
        end

        %{"command" => command, "key" => _, "value" => _} when command not in @commands ->
          raise Errors.InvalidCommandError, command

      _ ->
        raise Errors.ParseError
    end
  end
end

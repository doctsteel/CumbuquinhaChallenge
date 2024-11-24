defmodule CmbcWeb.CommandParserTest do
  use ExUnit.Case, async: true

  alias Cmbc.CommandParser, as: Command
  alias CmbcWeb.Errors, as: Err
  # command reference: COMMAND [KEY] [VALUE]
  # command must be one of the following: GET, SET, BEGIN, ROLLBACK, COMMIT
  # command GET must have a KEY
  # command SET must have a KEY and a VALUE
  # command BEGIN, ROLLBACK, and COMMIT must not have a KEY or a VALUE
  # a number is a sequence of digits
  # a boolean is the sequence of characters TRUE or FALSE without quotes
  # a string can be either a sequence of alphanumeric characters without quotes if no spaces
  # or a sequence of alphanumeric characters and spaces enclosed in double quotes
  # if a string has a quote, it must be escaped with a backslash
  # KEY must be a string
  # VALUE can be number, string or boolean
  describe "parse_command/1" do
    test "parse_command/1 correct syntax cases" do
      assert Command.parse("GET") == {:ok, ["GET"]}
      assert Command.parse("SET") == {:ok, ["SET"]}
      assert Command.parse("BEGIN") == {:ok, ["BEGIN"]}
      assert Command.parse("ROLLBACK") == {:ok, ["ROLLBACK"]}
      assert Command.parse("COMMIT") == {:ok, ["COMMIT"]}
      assert Command.parse("GET key") == {:ok, ["GET", "key"]}
      assert Command.parse("SET \"key\"") == {:ok, ["SET", "\"key\""]}
      assert Command.parse("GET \"space test\"") == {:ok, ["GET", "\"space test\""]}
      assert Command.parse("SET key") == {:ok, ["SET", "key"]}
      assert Command.parse("SET key value") == {:ok, ["SET", "key", "value"]}
      assert Command.parse("SET key \"value\"") == {:ok, ["SET", "key", "\"value\""]}

      assert Command.parse("SET key \"value with spaces\"") ==
               {:ok, ["SET", "key", "\"value with spaces\""]}

      assert Command.parse("SET key \"value with spaces and \\\"quotes\\\"\"") ==
               {:ok, ["SET", "key", "\"value with spaces and \\\"quotes\\\"\""]}

      assert Command.parse("SET key \"space test\"") == {:ok, ["SET", "key", "\"space test\""]}
      assert Command.parse("SET key TRUE") == {:ok, ["SET", "key", "TRUE"]}
      assert Command.parse("SET key FALSE") == {:ok, ["SET", "key", "FALSE"]}
      assert Command.parse("SET key 123") == {:ok, ["SET", "key", "123"]}
      assert Command.parse("SET ke\"y 0") == {:ok, ["SET", "ke\"y", "0"]}
      assert Command.parse("SET key 1234567890") == {:ok, ["SET", "key", "1234567890"]}

      assert Command.parse("SET \"key space\" \"value space\"") ==
               {:ok, ["SET", "\"key space\"", "\"value space\""]}

      assert Command.parse("SET \"TRUE\" \"value space\"") ==
               {:ok, ["SET", "\"TRUE\"", "\"value space\""]}
    end
  end

  test "parse_command/1 incorrect syntax cases" do
    assert_raise Err.ParseError, fn -> Command.parse("GET key value valueagain") end
    assert_raise Err.ParseError, fn -> Command.parse("PUT key value") end
    assert_raise Err.ParseError, fn -> Command.parse("PUT key") end
    assert_raise Err.ParseError, fn -> Command.parse("PUT") end
    assert_raise Err.KeyNotStringError, fn -> Command.parse("SET 123 value ") end
    assert_raise Err.KeyNotStringError, fn -> Command.parse("SET 123 \"value\" ") end
    assert_raise Err.ParseError, fn -> Command.parse("SET ke\"y val ue") end
    assert_raise Err.KeyNotStringError, fn -> Command.parse("SET TRUE value") end
    assert_raise Err.KeyNotStringError, fn -> Command.parse("SET FALSE value") end
  end
end

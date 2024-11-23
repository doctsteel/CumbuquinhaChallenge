defmodule CmbcWeb.CommandParserTest do
  use ExUnit.Case, async: true

  alias CmbcWeb.LilDBController, as: Cont
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
      assert Cont.parse_command("GET") == {:ok, ["GET"]}
      assert Cont.parse_command("SET") == {:ok, ["SET"]}
      assert Cont.parse_command("BEGIN") == {:ok, ["BEGIN"]}
      assert Cont.parse_command("ROLLBACK") == {:ok, ["ROLLBACK"]}
      assert Cont.parse_command("COMMIT") == {:ok, ["COMMIT"]}
      assert Cont.parse_command("GET key") == {:ok, ["GET", "key"]}
      assert Cont.parse_command("SET \"key\"") == {:ok, ["SET", "\"key\""]}
      assert Cont.parse_command("GET \"space test\"") == {:ok, ["GET", "\"space test\""]}
      assert Cont.parse_command("SET key") == {:ok, ["SET", "key"]}
      assert Cont.parse_command("SET key value") == {:ok, ["SET", "key", "value"]}
      assert Cont.parse_command("SET key \"value\"") == {:ok, ["SET", "key", "\"value\""]}
      assert Cont.parse_command("SET key \"value with spaces\"") == {:ok, ["SET", "key", "\"value with spaces\""]}
      assert Cont.parse_command("SET key \"value with spaces and \\\"quotes\\\"\"") == {:ok, ["SET", "key", "\"value with spaces and \\\"quotes\\\"\""]}
      assert Cont.parse_command("SET key \"space test\"") == {:ok, ["SET", "key", "\"space test\""]}
      assert Cont.parse_command("SET key TRUE") == {:ok, ["SET", "key", "TRUE"]}
      assert Cont.parse_command("SET key FALSE") == {:ok, ["SET", "key", "FALSE"]}
      assert Cont.parse_command("SET key 123") == {:ok, ["SET", "key", "123"]}
      assert Cont.parse_command("SET ke\"y 0") == {:ok, ["SET", "ke\"y", "0"]}
      assert Cont.parse_command("SET key 1234567890") == {:ok, ["SET", "key", "1234567890"]}
      assert Cont.parse_command("SET \"key space\" \"value space\"") == {:ok, ["SET", "\"key space\"", "\"value space\""]}
      assert Cont.parse_command("SET \"TRUE\" \"value space\"") == {:ok, ["SET", "\"TRUE\"", "\"value space\""]}
    end
  end

    test "parse_command/1 incorrect syntax cases" do
      assert_raise Err.ParseError, fn -> Cont.parse_command("GET key value valueagain") end
      assert_raise Err.ParseError, fn -> Cont.parse_command("PUT key value") end
      assert_raise Err.ParseError, fn -> Cont.parse_command("PUT key") end
      assert_raise Err.ParseError, fn -> Cont.parse_command("PUT") end
      assert_raise Err.KeyNotStringError, fn -> Cont.parse_command("SET 123 value ") end
      assert_raise Err.KeyNotStringError, fn -> Cont.parse_command("SET 123 \"value\" ") end
      assert_raise Err.ParseError, fn -> Cont.parse_command("SET ke\"y val ue") end
      assert_raise Err.KeyNotStringError, fn -> Cont.parse_command("SET TRUE value") end
      assert_raise Err.KeyNotStringError, fn -> Cont.parse_command("SET FALSE value") end
    end

end

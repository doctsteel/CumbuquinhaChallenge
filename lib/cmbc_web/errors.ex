defmodule CmbcWeb.Errors do
  defmodule ParseError do
    defexception message: "Invalid command format"
  end

  defmodule InvalidCommandError do
    defexception message: "Invalid command: "

    @impl true
    def exception(command) do
      %InvalidCommandError{message: "Invalid command: " <> command}
    end
  end

  defmodule InvalidHeaderError do
    defexception message: "x-client-name header not found"
  end

  defmodule KeyNotStringError do
    defexception message: "Key must be a string"

    @impl true
    def exception(key) do
      %KeyNotStringError{message: "Key "<> key <> " invalid: must be a string"}
    end
  end

  defmodule SetSyntaxError do
    defexception message: "SET Syntax error - Correct syntax: SET <key> <value>"
  end

  defmodule GetSyntaxError do
    defexception message: "GET Syntax error - Correct syntax: GET <key>"
  end

  defmodule BeginSyntaxError do
    defexception message: "BEGIN Syntax error - Correct syntax: BEGIN"
  end

  defmodule RollbackSyntaxError do
    defexception message: "ROLLBACK Syntax error - Correct syntax: ROLLBACK"
  end

  defmodule CommitSyntaxError do
    defexception message: "COMMIT Syntax error - Correct syntax: COMMIT"
  end

  defmodule ValueIsNilError do
    defexception message: "Cannot set a key to NIL"
  end

  defmodule TransactionAlreadyActiveError do
    defexception message: "User already has a transaction happening"
  end

  defmodule TransactionInactiveError do
    defexception message: "User does not have a transaction active"
  end

  defmodule AtomicityError do
    defexception message: "Atomicity error in field(s): "

    @impl true
    def exception(values) do
      %AtomicityError{message: "Atomicity error in field(s): " <> Enum.join(values, ", ")}
    end
  end
end

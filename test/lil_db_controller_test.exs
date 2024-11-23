defmodule CmbcWeb.LilDBControllerTest do
  use CmbcWeb.ConnCase, async: true

  @test_file_path "test/mock_db/cumbuquinha_test.txt"
  @copy_from_path "test/mock_db/cumbuquinha_test_copy.txt"

  setup do
    File.cp!(@copy_from_path, @test_file_path)

    :ok
  end

  def custom_conn(clientname) do
    build_conn()
    |> put_req_header("x-client-name", clientname)
    |> put_req_header("content-type", "text/plain")
  end

  test "returns 200 with a valid GET command" do
    conn =
      custom_conn("userA")
      |> post("/", "GET redmage")

    assert conn.status == 200
    assert conn.resp_body == "NIL"

    conn =
      custom_conn("userA")
      |> post("/", "GET \"pog champ\"")

    assert conn.status == 200
    assert conn.resp_body == "123"

    conn =
      custom_conn("userA")
      |> post("/", "GET \"456\"")

    assert conn.status == 200
    assert conn.resp_body == "NIL"
  end

  test "returns 400 with invalid GET command" do
    conn =
      custom_conn("userA")
      |> post("/", "GET")

    assert conn.status == 400
    assert conn.resp_body == "Error: GET Syntax error - Correct syntax: GET <key>"

    conn =
      custom_conn("userA")
      |> post("/", "GET lahabrea 123")

    assert conn.status == 400
    assert conn.resp_body == "Error: GET Syntax error - Correct syntax: GET <key>"

    ## case when the key is a number
    conn =
      custom_conn("userA")
      |> post("/", "GET 123")

    assert conn.status == 400
    assert conn.resp_body == "Error: Key must be a string"
  end

  test "returns 200 with a valid SET command" do
    conn =
      custom_conn("userA")
      |> post("/", "SET blackmage 123")

    assert conn.status == 200
    assert conn.resp_body == "NIL 123"

    conn =
      custom_conn("userA")
      |> post("/", "SET \"key with spaces test\" TRUE")

    assert conn.status == 200
    assert conn.resp_body == "NIL TRUE"

    conn =
      custom_conn("userA")
      |> post("/", "SET \"123\" 123")

    assert conn.status == 200
    assert conn.resp_body == "NIL 123"
  end

  test "returns 400 with an invalid SET command" do
    conn =
      custom_conn("userA")
      |> post("/", "SET")

    assert conn.status == 400
    assert conn.resp_body == "Error: SET Syntax error - Correct syntax: SET <key> <value>"

    conn =
      custom_conn("userA")
      |> post("/", "SET whitemage")

    assert conn.status == 400
    assert conn.resp_body == "Error: SET Syntax error - Correct syntax: SET <key> <value>"

    conn =
      custom_conn("userA")
      |> post("/", "SET whitemage 123 123")

    assert conn.status == 400
    assert conn.resp_body == "Error: Invalid command format"

    conn =
      custom_conn("userA")
      |> post("/", "SET 123 123")

    assert conn.status == 400
    assert conn.resp_body == "Error: Key must be a string"
  end

  test "returns 200 with a valid BEGIN command" do
    conn =
      custom_conn("userA")
      |> post("/", "BEGIN")

    assert conn.status == 200
    assert conn.resp_body == "BEGIN"
  end

  test "returns 400 with an invalid BEGIN command" do
    conn =
      custom_conn("userB")
      |> post("/", "BEGIN")

    assert conn.status == 200
    assert conn.resp_body == "BEGIN"

    conn =
      custom_conn("userB")
      |> post("/", "BEGIN 123")

    assert conn.status == 400
    assert conn.resp_body == "Error: Key must be a string"

    conn =
      custom_conn("userB")
      |> post("/", "BEGIN 123 123")

    assert conn.status == 400
    assert conn.resp_body == "Error: Key must be a string"

    conn =
      custom_conn("userB")
      |> post("/", "BEGIN test")

    assert conn.status == 400
    assert conn.resp_body == "Error: BEGIN Syntax error - Correct syntax: BEGIN"

    conn =
      custom_conn("userB")
      |> post("/", "BEGIN")

    assert conn.status == 400
    assert conn.resp_body == "Error: User already has a transaction happening"
  end

  test "returns 200 with a valid ROLLBACK command" do
    _conn =
      custom_conn("userC")
      |> post("/", "BEGIN")

    _conn1 =
      custom_conn("userC")
      |> post("/", "SET warrior 123")

    conn2 =
      custom_conn("userC")
      |> post("/", "GET warrior")

    assert conn2.status == 200
    assert conn2.resp_body == "123"

    conn3 =
      custom_conn("userC")
      |> post("/", "ROLLBACK")

    assert conn3.status == 200
    assert conn3.resp_body == "ROLLBACK"

    conn4 =
      custom_conn("userC")
      |> post("/", "GET warrior")

    assert conn4.status == 200
    assert conn4.resp_body == "NIL"
  end

  test "returns 400 with an invalid ROLLBACK command" do
    conn =
      custom_conn("userD")
      |> post("/", "ROLLBACK")

    assert conn.status == 400
    assert conn.resp_body == "Error: User does not have a transaction active"

    conn =
      custom_conn("userD")
      |> post("/", "ROLLBACK 123")

    assert conn.status == 400
    assert conn.resp_body == "Error: Key must be a string"

    conn =
      custom_conn("userD")
      |> post("/", "ROLLBACK 123 123")

    assert conn.status == 400
    assert conn.resp_body == "Error: Key must be a string"

    conn =
      custom_conn("userD")
      |> post("/", "ROLLBACK test")

    assert conn.status == 400
    assert conn.resp_body == "Error: ROLLBACK Syntax error - Correct syntax: ROLLBACK"
  end

  test "returns 200 with a valid COMMIT command" do
    _conn =
      custom_conn("userE")
      |> post("/", "BEGIN")

    _conn1 =
      custom_conn("userE")
      |> post("/", "SET bluemage 123")

    conn2 =
      custom_conn("userE")
      |> post("/", "GET bluemage")

    assert conn2.status == 200
    assert conn2.resp_body == "123"

    conn3 =
      custom_conn("userE")
      |> post("/", "COMMIT")

    assert conn3.status == 200
    assert conn3.resp_body == "COMMIT"

    conn4 =
      custom_conn("userE")
      |> post("/", "GET bluemage")

    assert conn4.status == 200
    assert conn4.resp_body == "123"
  end

  test "returns 400 with an invalid COMMIT command" do
    conn =
      custom_conn("userF")
      |> post("/", "COMMIT")

    assert conn.status == 400
    assert conn.resp_body == "Error: User does not have a transaction active"

    conn =
      custom_conn("userF")
      |> post("/", "COMMIT 123")

    assert conn.status == 400
    assert conn.resp_body == "Error: Key must be a string"

    conn =
      custom_conn("userF")
      |> post("/", "COMMIT 123 123")

    assert conn.status == 400
    assert conn.resp_body == "Error: Key must be a string"

    conn =
      custom_conn("userF")
      |> post("/", "COMMIT test")

    assert conn.status == 400
    assert conn.resp_body == "Error: COMMIT Syntax error - Correct syntax: COMMIT"
  end

  test "returns 400 with atomicity error on COMMIT" do
    _conn =
      custom_conn("userG")
      |> post("/", "BEGIN")

    _conn1 =
      custom_conn("userG")
      |> post("/", "SET timemage 123")

    conn2 =
      custom_conn("userG")
      |> post("/", "GET timemage")

    assert conn2.status == 200
    assert conn2.resp_body == "123"

    _conn3 =
      custom_conn("userF")
      |> post("/", "SET timemage 456")

    conn4 =
      custom_conn("userG")
      |> post("/", "COMMIT")

    assert conn4.status == 400
    assert conn4.resp_body == "Error: Atomicity error in field(s): timemage"
  end
end

defmodule Rumbl.AccountsTest do
  use Rumbl.DataCase # <label id="code.data-case"/>

  alias Rumbl.Accounts
  alias Rumbl.Accounts.User

  describe "register_user/2" do
    @valid_attrs %{
      name: "User",
      username: "eva",
      credential: %{email: "eva@test", password: "secret"}
    }
    @invalid_attrs %{}

    test "with valid data inserts user" do # <label id="code.valid-data"/>
      assert {:ok, %User{id: id} = user} = Accounts.register_user(@valid_attrs)
      assert user.name == "User"
      assert user.username == "eva"
      assert user.credential.email == "eva@test"
      assert [%User{id: ^id}] = Accounts.list_users()
    end

    test "with invalid data does not insert user" do # <label id="code.invalid-data"/>
      assert {:error, _changeset} = Accounts.register_user(@invalid_attrs)
      assert Accounts.list_users() == []
    end

    test "enforces unique usernames" do # <label id="code.unique-usernames"/>
      assert {:ok, %User{id: id}} = Accounts.register_user(@valid_attrs)
      assert {:error, changeset} = Accounts.register_user(@valid_attrs)

      assert %{username: ["has already been taken"]} =
             errors_on(changeset)

      assert [%User{id: ^id}] = Accounts.list_users()
    end

    test "does not accept long usernames" do # <label id="code.changeset-errors-on"/>
      attrs = Map.put(@valid_attrs, :username, String.duplicate("a", 30))
      {:error, changeset} = Accounts.register_user(attrs)

      assert %{username: ["should be at most 20 character(s)"]} =
             errors_on(changeset)
      assert Accounts.list_users() == []
    end

    test "requires password to be at least 6 chars long" do # <label id="code.pass-length"/>
      attrs = put_in(@valid_attrs, [:credential, :password], "12345")
      {:error, changeset} = Accounts.register_user(attrs)

      assert %{password: ["should be at least 6 character(s)"]} =
             errors_on(changeset)[:credential]
      assert Accounts.list_users() == []
    end
  end

  describe "authenticate_by_email_and_pass/2" do
    @email "user@localhost"
    @pass "123456"

    setup do
      {:ok, user: user_fixture(email: @email, password: @pass)}
    end

    test "returns user with correct password", %{user: %User{id: id}} do # <label id="code.correct-pass"/>
      assert {:ok, %User{id: ^id}} =
             Accounts.authenticate_by_email_and_pass(@email, @pass)
    end

    test "returns unauthorized error with invalid password" do # <label id="code.bad-pass"/>
      assert {:error, :unauthorized} =
             Accounts.authenticate_by_email_and_pass(@email, "badpass")
    end

    test "returns not found error with no matching user for email" do # <label id="code.bad-email"/>
      assert {:error, :not_found} =
             Accounts.authenticate_by_email_and_pass("bademail@localhost", @pass)
    end
  end
end

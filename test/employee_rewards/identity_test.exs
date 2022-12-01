defmodule EmployeeRewards.IdentityTest do
  use EmployeeRewards.DataCase

  alias EmployeeRewards.Identity

  import EmployeeRewards.IdentityFixtures
  alias EmployeeRewards.Identity.{Credentials, CredentialsToken}

  describe "get_credentials_by_email/1" do
    test "does not return the credentials if the email does not exist" do
      refute Identity.get_credentials_by_email("unknown@example.com")
    end

    test "returns the credentials if the email exists" do
      %{id: id} = credentials = credentials_fixture()
      assert %Credentials{id: ^id} = Identity.get_credentials_by_email(credentials.email)
    end
  end

  describe "get_credentials_by_email_and_password/2" do
    test "does not return the credentials if the email does not exist" do
      refute Identity.get_credentials_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the credentials if the password is not valid" do
      credentials = credentials_fixture()
      refute Identity.get_credentials_by_email_and_password(credentials.email, "invalid")
    end

    test "returns the credentials if the email and password are valid" do
      %{id: id} = credentials = credentials_fixture()

      assert %Credentials{id: ^id} =
               Identity.get_credentials_by_email_and_password(credentials.email, valid_credentials_password())
    end
  end

  describe "get_credentials!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Identity.get_credentials!(-1)
      end
    end

    test "returns the credentials with the given id" do
      %{id: id} = credentials = credentials_fixture()
      assert %Credentials{id: ^id} = Identity.get_credentials!(credentials.id)
    end
  end

  describe "register_credentials/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Identity.register_credentials(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Identity.register_credentials(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Identity.register_credentials(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = credentials_fixture()
      {:error, changeset} = Identity.register_credentials(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Identity.register_credentials(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers credentials with a hashed password" do
      email = unique_credentials_email()
      {:ok, credentials} = Identity.register_credentials(valid_credentials_attributes(email: email))
      assert credentials.email == email
      assert is_binary(credentials.hashed_password)
      assert is_nil(credentials.confirmed_at)
      assert is_nil(credentials.password)
    end
  end

  describe "change_credentials_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Identity.change_credentials_registration(%Credentials{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_credentials_email()
      password = valid_credentials_password()

      changeset =
        Identity.change_credentials_registration(
          %Credentials{},
          valid_credentials_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_credentials_email/2" do
    test "returns a credentials changeset" do
      assert %Ecto.Changeset{} = changeset = Identity.change_credentials_email(%Credentials{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_credentials_email/3" do
    setup do
      %{credentials: credentials_fixture()}
    end

    test "requires email to change", %{credentials: credentials} do
      {:error, changeset} = Identity.apply_credentials_email(credentials, valid_credentials_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{credentials: credentials} do
      {:error, changeset} =
        Identity.apply_credentials_email(credentials, valid_credentials_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{credentials: credentials} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Identity.apply_credentials_email(credentials, valid_credentials_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{credentials: credentials} do
      %{email: email} = credentials_fixture()

      {:error, changeset} =
        Identity.apply_credentials_email(credentials, valid_credentials_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{credentials: credentials} do
      {:error, changeset} =
        Identity.apply_credentials_email(credentials, "invalid", %{email: unique_credentials_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{credentials: credentials} do
      email = unique_credentials_email()
      {:ok, credentials} = Identity.apply_credentials_email(credentials, valid_credentials_password(), %{email: email})
      assert credentials.email == email
      assert Identity.get_credentials!(credentials.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{credentials: credentials_fixture()}
    end

    test "sends token through notification", %{credentials: credentials} do
      token =
        extract_credentials_token(fn url ->
          Identity.deliver_update_email_instructions(credentials, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert credentials_token = Repo.get_by(CredentialsToken, token: :crypto.hash(:sha256, token))
      assert credentials_token.credentials_id == credentials.id
      assert credentials_token.sent_to == credentials.email
      assert credentials_token.context == "change:current@example.com"
    end
  end

  describe "update_credentials_email/2" do
    setup do
      credentials = credentials_fixture()
      email = unique_credentials_email()

      token =
        extract_credentials_token(fn url ->
          Identity.deliver_update_email_instructions(%{credentials | email: email}, credentials.email, url)
        end)

      %{credentials: credentials, token: token, email: email}
    end

    test "updates the email with a valid token", %{credentials: credentials, token: token, email: email} do
      assert Identity.update_credentials_email(credentials, token) == :ok
      changed_credentials = Repo.get!(Credentials, credentials.id)
      assert changed_credentials.email != credentials.email
      assert changed_credentials.email == email
      assert changed_credentials.confirmed_at
      assert changed_credentials.confirmed_at != credentials.confirmed_at
      refute Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end

    test "does not update email with invalid token", %{credentials: credentials} do
      assert Identity.update_credentials_email(credentials, "oops") == :error
      assert Repo.get!(Credentials, credentials.id).email == credentials.email
      assert Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end

    test "does not update email if credentials email changed", %{credentials: credentials, token: token} do
      assert Identity.update_credentials_email(%{credentials | email: "current@example.com"}, token) == :error
      assert Repo.get!(Credentials, credentials.id).email == credentials.email
      assert Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end

    test "does not update email if token expired", %{credentials: credentials, token: token} do
      {1, nil} = Repo.update_all(CredentialsToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Identity.update_credentials_email(credentials, token) == :error
      assert Repo.get!(Credentials, credentials.id).email == credentials.email
      assert Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end
  end

  describe "change_credentials_password/2" do
    test "returns a credentials changeset" do
      assert %Ecto.Changeset{} = changeset = Identity.change_credentials_password(%Credentials{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Identity.change_credentials_password(%Credentials{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_credentials_password/3" do
    setup do
      %{credentials: credentials_fixture()}
    end

    test "validates password", %{credentials: credentials} do
      {:error, changeset} =
        Identity.update_credentials_password(credentials, valid_credentials_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{credentials: credentials} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Identity.update_credentials_password(credentials, valid_credentials_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{credentials: credentials} do
      {:error, changeset} =
        Identity.update_credentials_password(credentials, "invalid", %{password: valid_credentials_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{credentials: credentials} do
      {:ok, credentials} =
        Identity.update_credentials_password(credentials, valid_credentials_password(), %{
          password: "new valid password"
        })

      assert is_nil(credentials.password)
      assert Identity.get_credentials_by_email_and_password(credentials.email, "new valid password")
    end

    test "deletes all tokens for the given credentials", %{credentials: credentials} do
      _ = Identity.generate_credentials_session_token(credentials)

      {:ok, _} =
        Identity.update_credentials_password(credentials, valid_credentials_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end
  end

  describe "generate_credentials_session_token/1" do
    setup do
      %{credentials: credentials_fixture()}
    end

    test "generates a token", %{credentials: credentials} do
      token = Identity.generate_credentials_session_token(credentials)
      assert credentials_token = Repo.get_by(CredentialsToken, token: token)
      assert credentials_token.context == "session"

      # Creating the same token for another credentials should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%CredentialsToken{
          token: credentials_token.token,
          credentials_id: credentials_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_credentials_by_session_token/1" do
    setup do
      credentials = credentials_fixture()
      token = Identity.generate_credentials_session_token(credentials)
      %{credentials: credentials, token: token}
    end

    test "returns credentials by token", %{credentials: credentials, token: token} do
      assert session_credentials = Identity.get_credentials_by_session_token(token)
      assert session_credentials.id == credentials.id
    end

    test "does not return credentials for invalid token" do
      refute Identity.get_credentials_by_session_token("oops")
    end

    test "does not return credentials for expired token", %{token: token} do
      {1, nil} = Repo.update_all(CredentialsToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Identity.get_credentials_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      credentials = credentials_fixture()
      token = Identity.generate_credentials_session_token(credentials)
      assert Identity.delete_session_token(token) == :ok
      refute Identity.get_credentials_by_session_token(token)
    end
  end

  describe "deliver_credentials_confirmation_instructions/2" do
    setup do
      %{credentials: credentials_fixture()}
    end

    test "sends token through notification", %{credentials: credentials} do
      token =
        extract_credentials_token(fn url ->
          Identity.deliver_credentials_confirmation_instructions(credentials, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert credentials_token = Repo.get_by(CredentialsToken, token: :crypto.hash(:sha256, token))
      assert credentials_token.credentials_id == credentials.id
      assert credentials_token.sent_to == credentials.email
      assert credentials_token.context == "confirm"
    end
  end

  describe "confirm_credentials/1" do
    setup do
      credentials = credentials_fixture()

      token =
        extract_credentials_token(fn url ->
          Identity.deliver_credentials_confirmation_instructions(credentials, url)
        end)

      %{credentials: credentials, token: token}
    end

    test "confirms the email with a valid token", %{credentials: credentials, token: token} do
      assert {:ok, confirmed_credentials} = Identity.confirm_credentials(token)
      assert confirmed_credentials.confirmed_at
      assert confirmed_credentials.confirmed_at != credentials.confirmed_at
      assert Repo.get!(Credentials, credentials.id).confirmed_at
      refute Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end

    test "does not confirm with invalid token", %{credentials: credentials} do
      assert Identity.confirm_credentials("oops") == :error
      refute Repo.get!(Credentials, credentials.id).confirmed_at
      assert Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end

    test "does not confirm email if token expired", %{credentials: credentials, token: token} do
      {1, nil} = Repo.update_all(CredentialsToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Identity.confirm_credentials(token) == :error
      refute Repo.get!(Credentials, credentials.id).confirmed_at
      assert Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end
  end

  describe "deliver_credentials_reset_password_instructions/2" do
    setup do
      %{credentials: credentials_fixture()}
    end

    test "sends token through notification", %{credentials: credentials} do
      token =
        extract_credentials_token(fn url ->
          Identity.deliver_credentials_reset_password_instructions(credentials, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert credentials_token = Repo.get_by(CredentialsToken, token: :crypto.hash(:sha256, token))
      assert credentials_token.credentials_id == credentials.id
      assert credentials_token.sent_to == credentials.email
      assert credentials_token.context == "reset_password"
    end
  end

  describe "get_credentials_by_reset_password_token/1" do
    setup do
      credentials = credentials_fixture()

      token =
        extract_credentials_token(fn url ->
          Identity.deliver_credentials_reset_password_instructions(credentials, url)
        end)

      %{credentials: credentials, token: token}
    end

    test "returns the credentials with valid token", %{credentials: %{id: id}, token: token} do
      assert %Credentials{id: ^id} = Identity.get_credentials_by_reset_password_token(token)
      assert Repo.get_by(CredentialsToken, credentials_id: id)
    end

    test "does not return the credentials with invalid token", %{credentials: credentials} do
      refute Identity.get_credentials_by_reset_password_token("oops")
      assert Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end

    test "does not return the credentials if token expired", %{credentials: credentials, token: token} do
      {1, nil} = Repo.update_all(CredentialsToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Identity.get_credentials_by_reset_password_token(token)
      assert Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end
  end

  describe "reset_credentials_password/2" do
    setup do
      %{credentials: credentials_fixture()}
    end

    test "validates password", %{credentials: credentials} do
      {:error, changeset} =
        Identity.reset_credentials_password(credentials, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{credentials: credentials} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Identity.reset_credentials_password(credentials, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{credentials: credentials} do
      {:ok, updated_credentials} = Identity.reset_credentials_password(credentials, %{password: "new valid password"})
      assert is_nil(updated_credentials.password)
      assert Identity.get_credentials_by_email_and_password(credentials.email, "new valid password")
    end

    test "deletes all tokens for the given credentials", %{credentials: credentials} do
      _ = Identity.generate_credentials_session_token(credentials)
      {:ok, _} = Identity.reset_credentials_password(credentials, %{password: "new valid password"})
      refute Repo.get_by(CredentialsToken, credentials_id: credentials.id)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%Credentials{password: "123456"}) =~ "password: \"123456\""
    end
  end
end

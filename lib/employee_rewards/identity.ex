defmodule EmployeeRewards.Identity do
  @moduledoc """
  The Identity context.
  """

  import Ecto.Query, warn: false
  alias EmployeeRewards.Repo

  alias EmployeeRewards.Identity.{Credentials, CredentialsToken, CredentialsNotifier}

  ## Database getters

  @doc """
  Gets a credentials by email.

  ## Examples

      iex> get_credentials_by_email("foo@example.com")
      %Credentials{}

      iex> get_credentials_by_email("unknown@example.com")
      nil

  """
  def get_credentials_by_email(email) when is_binary(email) do
    Repo.get_by(Credentials, email: email)
  end

  @doc """
  Gets a credentials by email and password.

  ## Examples

      iex> get_credentials_by_email_and_password("foo@example.com", "correct_password")
      %Credentials{}

      iex> get_credentials_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_credentials_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    credentials = Repo.get_by(Credentials, email: email)
    if Credentials.valid_password?(credentials, password), do: credentials
  end

  @doc """
  Gets a single credentials.

  Raises `Ecto.NoResultsError` if the Credentials does not exist.

  ## Examples

      iex> get_credentials!(123)
      %Credentials{}

      iex> get_credentials!(456)
      ** (Ecto.NoResultsError)

  """
  def get_credentials!(id), do: Repo.get!(Credentials, id)

  ## Credentials registration

  @doc """
  Registers a credentials.

  ## Examples

      iex> register_credentials(%{field: value})
      {:ok, %Credentials{}}

      iex> register_credentials(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_credentials(attrs) do
    %Credentials{}
    |> Credentials.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking credentials changes.

  ## Examples

      iex> change_credentials_registration(credentials)
      %Ecto.Changeset{data: %Credentials{}}

  """
  def change_credentials_registration(%Credentials{} = credentials, attrs \\ %{}) do
    Credentials.registration_changeset(credentials, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the credentials email.

  ## Examples

      iex> change_credentials_email(credentials)
      %Ecto.Changeset{data: %Credentials{}}

  """
  def change_credentials_email(credentials, attrs \\ %{}) do
    Credentials.email_changeset(credentials, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_credentials_email(credentials, "valid password", %{email: ...})
      {:ok, %Credentials{}}

      iex> apply_credentials_email(credentials, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_credentials_email(credentials, password, attrs) do
    credentials
    |> Credentials.email_changeset(attrs)
    |> Credentials.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the credentials email using the given token.

  If the token matches, the credentials email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_credentials_email(credentials, token) do
    context = "change:#{credentials.email}"

    with {:ok, query} <- CredentialsToken.verify_change_email_token_query(token, context),
         %CredentialsToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(credentials_email_multi(credentials, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp credentials_email_multi(credentials, email, context) do
    changeset =
      credentials
      |> Credentials.email_changeset(%{email: email})
      |> Credentials.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:credentials, changeset)
    |> Ecto.Multi.delete_all(:tokens, CredentialsToken.credentials_and_contexts_query(credentials, [context]))
  end

  @doc """
  Delivers the update email instructions to the given credentials.

  ## Examples

      iex> deliver_update_email_instructions(credentials, current_email, &Routes.credentials_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%Credentials{} = credentials, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, credentials_token} = CredentialsToken.build_email_token(credentials, "change:#{current_email}")

    Repo.insert!(credentials_token)
    CredentialsNotifier.deliver_update_email_instructions(credentials, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the credentials password.

  ## Examples

      iex> change_credentials_password(credentials)
      %Ecto.Changeset{data: %Credentials{}}

  """
  def change_credentials_password(credentials, attrs \\ %{}) do
    Credentials.password_changeset(credentials, attrs, hash_password: false)
  end

  @doc """
  Updates the credentials password.

  ## Examples

      iex> update_credentials_password(credentials, "valid password", %{password: ...})
      {:ok, %Credentials{}}

      iex> update_credentials_password(credentials, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_credentials_password(credentials, password, attrs) do
    changeset =
      credentials
      |> Credentials.password_changeset(attrs)
      |> Credentials.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:credentials, changeset)
    |> Ecto.Multi.delete_all(:tokens, CredentialsToken.credentials_and_contexts_query(credentials, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{credentials: credentials}} -> {:ok, credentials}
      {:error, :credentials, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_credentials_session_token(credentials) do
    {token, credentials_token} = CredentialsToken.build_session_token(credentials)
    Repo.insert!(credentials_token)
    token
  end

  @doc """
  Gets the credentials with the given signed token.
  """
  def get_credentials_by_session_token(token) do
    {:ok, query} = CredentialsToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(CredentialsToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given credentials.

  ## Examples

      iex> deliver_credentials_confirmation_instructions(credentials, &Routes.credentials_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_credentials_confirmation_instructions(confirmed_credentials, &Routes.credentials_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}

  """
  def deliver_credentials_confirmation_instructions(%Credentials{} = credentials, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if credentials.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, credentials_token} = CredentialsToken.build_email_token(credentials, "confirm")
      Repo.insert!(credentials_token)
      CredentialsNotifier.deliver_confirmation_instructions(credentials, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a credentials by the given token.

  If the token matches, the credentials account is marked as confirmed
  and the token is deleted.
  """
  def confirm_credentials(token) do
    with {:ok, query} <- CredentialsToken.verify_email_token_query(token, "confirm"),
         %Credentials{} = credentials <- Repo.one(query),
         {:ok, %{credentials: credentials}} <- Repo.transaction(confirm_credentials_multi(credentials)) do
      {:ok, credentials}
    else
      _ -> :error
    end
  end

  defp confirm_credentials_multi(credentials) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:credentials, Credentials.confirm_changeset(credentials))
    |> Ecto.Multi.delete_all(:tokens, CredentialsToken.credentials_and_contexts_query(credentials, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given credentials.

  ## Examples

      iex> deliver_credentials_reset_password_instructions(credentials, &Routes.credentials_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_credentials_reset_password_instructions(%Credentials{} = credentials, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, credentials_token} = CredentialsToken.build_email_token(credentials, "reset_password")
    Repo.insert!(credentials_token)
    CredentialsNotifier.deliver_reset_password_instructions(credentials, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the credentials by reset password token.

  ## Examples

      iex> get_credentials_by_reset_password_token("validtoken")
      %Credentials{}

      iex> get_credentials_by_reset_password_token("invalidtoken")
      nil

  """
  def get_credentials_by_reset_password_token(token) do
    with {:ok, query} <- CredentialsToken.verify_email_token_query(token, "reset_password"),
         %Credentials{} = credentials <- Repo.one(query) do
      credentials
    else
      _ -> nil
    end
  end

  @doc """
  Resets the credentials password.

  ## Examples

      iex> reset_credentials_password(credentials, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Credentials{}}

      iex> reset_credentials_password(credentials, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_credentials_password(credentials, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:credentials, Credentials.password_changeset(credentials, attrs))
    |> Ecto.Multi.delete_all(:tokens, CredentialsToken.credentials_and_contexts_query(credentials, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{credentials: credentials}} -> {:ok, credentials}
      {:error, :credentials, changeset, _} -> {:error, changeset}
    end
  end
end

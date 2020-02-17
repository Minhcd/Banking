defmodule Hello.Usermanage do
    use Ecto.Schema
    import Ecto.Changeset
    alias Hello.Usermanage
    alias Argon2

    schema "users" do
      field :account, :string
      field :password, :string
      field :money, :integer
    end
    @doc false
    def changeset(%Usermanage{} = user, attrs) do
      user
      |> cast(attrs,[:account, :password, :money])
      |> validate_required([:money])
    end

    def insert_changeset(%Usermanage{}=user, attrs) do
      user
      |> cast(attrs,[:account, :password, :money])
      |> validate_required([:account, :password])
      |> put_password_hash()
    end
    
    defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = insert_changeset) do
      change(insert_changeset, password: Argon2.hash_pwd_salt(password))
    end
    
    defp put_password_hash(insert_changeset), do: insert_changeset
  end


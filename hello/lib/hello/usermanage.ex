defmodule Hello.Usermanage do
    use Ecto.Schema
    import Ecto.Changeset
    import Ecto.Query
    alias Hello.{Usermanage,Repo}
    alias Bcrypt

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
      change(insert_changeset, password: Bcrypt.hash_pwd_salt(password))
    end
    
    defp put_password_hash(insert_changeset), do: insert_changeset

    def show_id(account) do
      Usermanage
      |> where([u], u.account == ^account)
      |> select([u], u.id)
      |> Repo.one()
    end

    def insert_user(account, password) do
      params = %{account: account, password: password}
      insert_changeset = insert_changeset(%Usermanage{}, params)
      Repo.insert(insert_changeset)
    end

    def check_user(account, password) do
      Usermanage
      |> where([u], u.account == ^account and u.password == ^password)
      |> select([u], u.id)
      |> Repo.one()
    end

    def show_money(id) do
      Usermanage
      |> where([u], u.id == ^id)
      |> select([u], u.money)
      |> Repo.one()
    end


    def update_money(id,money) do
        params = %{money: money}
        changeset = changeset(%Usermanage{id: elem(Integer.parse(id),0)},params)
        Repo.update(changeset)
    end
end

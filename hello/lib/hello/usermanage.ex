defmodule Hello.Usermanage do
    use Ecto.Schema
    import Ecto.Query
    import Ecto.Changeset
    alias Hello.{Usermanage,Repo}
    

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
      |> validate_length(:password, min: 8)
      |> unique_constraint(:account)

    end
    

    


  def show_id(account) do
    Usermanage
    |> where([u], u.account == ^account)
    |> select([u], u.id)
    |> Repo.one()
  end

  def get_user(id) do
    Usermanage
    |> Repo.get(id)
  end

  def insert_user(account, password) do
    params = %{account: account, password: password}
    insert_changeset = insert_changeset(%Usermanage{}, params)
    Repo.insert(insert_changeset)
  end

  def check_user(account, password) do
    id = Usermanage
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

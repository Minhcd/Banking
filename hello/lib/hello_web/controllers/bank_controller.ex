defmodule HelloWeb.BankController do
    use HelloWeb,:controller
    alias Hello.{Usermanage,Repo}
    import Ecto.Query
    

    def index(conn,_params) do
      render(conn,_params) 
    end
    def signup(conn,_params) do
    
      render conn,"signup.html", token: get_csrf_token()
    end
    def signin(conn,_params) do 
      render(conn,"signin.html", token: get_csrf_token())
    end

    def signuphandler(conn,%{"account"=>account,"password"=>password})do
      Repo.insert(%Usermanage{account: account,password: password})
      redirect(conn,to: "/bank/account/#{account}")
    end

    def signinhandler(conn,%{"account"=>account,"password"=>password}) do
      query = from u in Usermanage, where: u.account == ^account and u.password == ^password, select: u.id
      result = Repo.one(query)
      if result != nil do
        redirect(conn,to: "/bank/account/#{account}/#{result}")
        # render(conn,"show.html",account: account,money: money)
      else
        render(conn,"loginfalse.html")
      end
    end

    def account(conn,%{"name"=>account,"id"=>id}) do
      query = from u in Usermanage, where: u.id == ^id, select: u.money
      deposit = Repo.one(query)
      render(conn,"show.html",money: deposit,account: account,token: get_csrf_token())
    end

    def deposit(conn,%{"name"=>account,"id"=>id,"deposit"=>deposit,"withdraw"=>withdraw,"submit"=>submit})do
      query = from u in Usermanage, where: u.id == ^id, select: u.money
      money = Repo.one(query)
      if submit == "deposit" do
      money = Repo.one(query) + elem(Integer.parse(deposit),0)
      params = %{money: money}
      changeset = Usermanage.changeset(%Usermanage{id: elem(Integer.parse(id),0)},params)
      Repo.update(changeset)
      render(conn,"show.html",money: money,account: account,token: get_csrf_token())
      else if submit == "withdraw" do
      money = Repo.one(query) - elem(Integer.parse(withdraw),0)
      params = %{money: money}
      changeset = Usermanage.changeset(%Usermanage{id: elem(Integer.parse(id),0)},params)
      Repo.update(changeset)
      render(conn,"show.html",money: money,account: account,token: get_csrf_token())
      end
      end

      
    end



end

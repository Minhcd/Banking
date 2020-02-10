defmodule HelloWeb.BankController do
    use HelloWeb,:controller
    alias Hello.{Usermanage,Repo}
    alias HelloWeb.Router.Helpers
    import Ecto.Query

    # plug LearningPlug, %{}
    # plug :test
    plug HelloWeb.Plugs.AuthenticateUser when action in [:account, :deposit, :transaction, :transactionhanler]
    plug HelloWeb.Plugs.Authorization when action in [:account, :deposit, :transaction, :transactionhanler]
    plug :home_page when action in [:index, :signin]
    

    def index(conn,_params) do
      render(conn,_params) 
      # IO.inspect conn
    end

    def signup(conn,_params) do
      render conn,"signup.html", token: get_csrf_token()
    end
    def signin(conn,_params) do 
      render(conn,"signin.html", token: get_csrf_token())
    end

    def signuphandler(conn,%{"account"=>account,"password"=>password}) do
      id = Usermanage 
              |> where([u], u.account == ^account) 
              |> select([u], u.id)
              |> Repo.one()
      if id != nil do
        conn
        |> put_flash(:error, "Tên đăng nhập đã tồn tại")
        |> redirect(to: Helpers.bank_path(conn, :signup))
        |> halt()
      else
        Repo.insert(%Usermanage{account: account,password: password})
        #conn |> redirect(to: "/bank/account/#{account}")
        conn |> redirect(to: "/bank/signin")
      end
    end


    def signinhandler(conn,%{"account"=>account,"password"=>password}) do
      id = Usermanage 
              |> where([u], u.account == ^account and u.password == ^password) 
              |> select([u], u.id)
              |> Repo.one()
      if id != nil do
        conn 
        |>put_session(:user_id,id)
        |>put_session(:user_account,account)
        |>redirect(to: "/bank/account/#{account}/#{id}")
        # render(conn,"show.html",account: account,money: money)
        # IO.inspect conn
      else
        #render(conn,"loginfalse.html")
        conn
        |> put_flash(:error, "Tên đăng nhập hoặc mật khẩu không hợp lệ")
        |> redirect(to: Helpers.bank_path(conn, :signin))
        |> halt()
      end
    end

    def account(conn,%{"name"=>account,"id"=>id}) do
      
      deposit = Usermanage 
                |> where([u], u.id == ^id )
                |> select([u], u.money)
                |> Repo.one()      
      conn  |> assign(:current_user_id, id)
            |> render("show.html",money: deposit,account: account,id: id,token: get_csrf_token())
      # IO.inspect conn
    end

    def deposit(conn,%{"name"=>account,"id"=>id,"deposit"=>deposit,"withdraw"=>withdraw,"submit"=>submit})do
      money = Usermanage 
              |> where([u],u.id == ^id)
              |> select([u], u.money)
              |> Repo.one()
      if submit == "deposit" do
      money = money + elem(Integer.parse(deposit),0)
      params = %{money: money}
      changeset = Usermanage.changeset(%Usermanage{id: elem(Integer.parse(id),0)},params)
      Repo.update(changeset)
      conn |> redirect(to: Helpers.bank_path(conn, :account,account,id))
      else if submit == "withdraw" do
      money = money - elem(Integer.parse(withdraw),0)
      params = %{money: money}
      changeset = Usermanage.changeset(%Usermanage{id: elem(Integer.parse(id),0)},params)
      Repo.update(changeset)
      conn |> redirect(to: Helpers.bank_path(conn, :account,account,id))
      else
      conn 
      |> clear_session()
      |> redirect(to: Helpers.bank_path(conn, :signin))
      end
      end    
      # IO.inspect conn
    end


    def transaction(conn,%{"name"=>account,"id"=>id}) do 
      render(conn,"transaction.html",account: account,id: id,token: get_csrf_token())
    end

    def transactionhandler(conn,%{"receiverid"=>receiverid,"receivername"=>receivername,"money"=>money,"name"=>name,"id"=>id}) do
      money = elem(Integer.parse(money),0)
      target_money = Usermanage
                    |> where([u], u.id == ^receiverid and u.account ==^receivername)
                    |> select([u], u.money)
                    |> Repo.one() 
      target_money = target_money + money
      source_money = Usermanage
                    |> where([u], u.id == ^id and u.account ==^name)
                    |> select([u], u.money)
                    |> Repo.one() 
      source_money = source_money - money                    
      target_params=%{money: target_money}
      source_params=%{money: source_money}
      source_changeset = Usermanage.changeset(%Usermanage{id: elem(Integer.parse(id),0)},source_params)
      target_changeset = Usermanage.changeset(%Usermanage{id: elem(Integer.parse(receiverid),0)},target_params)
      Repo.update(source_changeset)
      Repo.update(target_changeset)
      conn |> redirect(to: Helpers.bank_path(conn, :transaction, name,id))
      # render(conn,"transaction.html",account: name,id: id,token: get_csrf_token())
    end

    def home_page(conn,_params) do
      user_signed_in? = conn.assigns[:user_signed_in?]
      if user_signed_in? do
        user_id =   conn.assigns[:user_id]
        user_account = conn.assigns[:user_account]
        conn 
        |> redirect(to: Helpers.bank_path(conn, :account, user_account, user_id))
      else
        conn
      end

    end
end


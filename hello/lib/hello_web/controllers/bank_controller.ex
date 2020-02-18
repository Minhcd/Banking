defmodule HelloWeb.BankController do
    use HelloWeb,:controller
    alias Hello.{Usermanage,Repo,HistoryTransaction}
    alias HelloWeb.Router.Helpers
    alias Argon2
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
      id = Usermanage.show_id(account)
      if id != nil do
        conn
        |> put_flash(:error, "Tên đăng nhập đã tồn tại")
        |> redirect(to: Helpers.bank_path(conn, :signup))
        |> halt()
      else
        Usermanage.insert_user(account,password)
        conn |> redirect(to: "/bank/signin")
      end
    end


    def signinhandler(conn,%{"account"=>account,"password"=>password}) do
      query = Usermanage |> where([u], u.account == ^account) 
      case Repo.one(query) do
        nil ->
          conn
          |> put_flash(:error, "Tên đăng nhập hoặc mật khẩu không hợp lệ")
          |> redirect(to: Helpers.bank_path(conn, :signin))
          |> halt()
        user ->
          if Argon2.verify_pass(password, user.password) do
            conn 
            |>put_session(:user_id,user.id)
            |>put_session(:user_account,user.account)
            |>redirect(to: "/bank/account/#{user.account}/#{user.id}")
          else
            conn
            |> put_flash(:error, "Tên đăng nhập hoặc mật khẩu không hợp lệ")
            |> redirect(to: Helpers.bank_path(conn, :signin))
            |> halt()
          end
      end        
    end

    def account(conn,%{"name"=>account,"id"=>id}) do  
      deposit = Usermanage.show_money(id) 
      conn  |> assign(:current_user_id, id)
            |> render("show.html",money: deposit,account: account,id: id,token: get_csrf_token())
    end

    def deposit(conn,%{"name"=>account,"id"=>id,"deposit"=>deposit,"withdraw"=>withdraw,"submit"=>submit})do
      money = Usermanage.show_money(id)
      if submit == "deposit" do
      HistoryTransaction.create_datetime(
        %{
          user_id: id,
          datetime: DateTime.utc_now,
          action: submit,
          money: elem(Integer.parse(deposit),0)
          })
      money = money + elem(Integer.parse(deposit),0)
      Usermanage.update_money(id,money)
      conn |> redirect(to: Helpers.bank_path(conn, :account,account,id))
      else if submit == "withdraw" do
      HistoryTransaction.create_datetime(
        %{
          user_id: id,
          datetime: DateTime.utc_now,
          action: submit,
          money: elem(Integer.parse(withdraw),0)
          })
      money = money - elem(Integer.parse(withdraw),0)
      Usermanage.update_money(id,money)
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
      HistoryTransaction.create_transfertime(
        %{
          user_id: id,
          datetime: DateTime.utc_now,
          action: "transfer",
          receiver_id: receiverid,          
          money: money
          })
      if elem(Integer.parse(receiverid),0) == Usermanage.show_id(receivername) do
      target_money = Usermanage.show_money(receiverid)
      source_money = Usermanage.show_money(id)
      target_money = target_money + money
      source_money = source_money - money
      Usermanage.update_money(receiverid,target_money)
      Usermanage.update_money(id,source_money)                      
      end
      conn |> redirect(to: Helpers.bank_path(conn, :transaction, name,id))
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


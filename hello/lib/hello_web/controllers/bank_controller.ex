defmodule HelloWeb.BankController do
    use HelloWeb,:controller
    alias Hello.{Usermanage,Repo,HistoryTransaction,Socialusermanage}
    alias HelloWeb.Router.Helpers
    alias Bcrypt
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
          if Bcrypt.verify_pass(password,user.password) do
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
      deposit_user = Usermanage.show_money(id)
      deposit_socialuser = Socialusermanage.show_money(id)
      if (deposit_user != nil) do
        conn  |> assign(:current_user_id, id)
              |> render("show.html",money: deposit_user,account: account,id: id,token: get_csrf_token())
      else  
        if (deposit_socialuser != nil) do
          conn  |> assign(:current_user_id, id)
                |> render("show.html",money: deposit_user,account: account,id: id,token: get_csrf_token())
        end        
      end
    end

    def deposit(conn,%{"name"=>account,"id"=>id,"deposit"=>deposit,"withdraw"=>withdraw,"submit"=>submit})do
      money_user = Usermanage.show_money(id)
      money_socialuser = Socialusermanage.show_money(id)
      if (money_user != nil) do
        if submit == "deposit" do
        HistoryTransaction.create_datetime(
          %{
            user_id: id,
            datetime: DateTime.utc_now,
            action: submit,
            money: elem(Integer.parse(deposit),0)
            })
        money_user = money_user + elem(Integer.parse(deposit),0)
        Usermanage.update_money(id,money_user)
        conn |> redirect(to: Helpers.bank_path(conn, :account,account,id))
        else if submit == "withdraw" do
        HistoryTransaction.create_datetime(
          %{
            user_id: id,
            datetime: DateTime.utc_now,
            action: submit,
            money: elem(Integer.parse(withdraw),0)
            })
        money_user = money_user - elem(Integer.parse(withdraw),0)
        Usermanage.update_money(id,money_user)
        conn |> redirect(to: Helpers.bank_path(conn, :account,account,id))
        else
        conn 
        |> clear_session()
        |> redirect(to: Helpers.bank_path(conn, :signin))
        end
        end
      else
        if (money_socialuser != nil) do
          if submit == "deposit" do
            HistoryTransaction.create_datetime(
              %{
                user_id: id,
                datetime: DateTime.utc_now,
                action: submit,
                money: elem(Integer.parse(deposit),0)
                })
            money_socialuser = money_socialuser + elem(Integer.parse(deposit),0)
            Usermanage.update_money(id,money_socialuser)
            conn |> redirect(to: Helpers.bank_path(conn, :account,account,id))
            else if submit == "withdraw" do
            HistoryTransaction.create_datetime(
              %{
                user_id: id,
                datetime: DateTime.utc_now,
                action: submit,
                money: elem(Integer.parse(withdraw),0)
                })
            money_socialuser = money_socialuser - elem(Integer.parse(withdraw),0)
            Usermanage.update_money(id,money_socialuser)
            conn |> redirect(to: Helpers.bank_path(conn, :account,account,id))
            else
            conn 
            |> clear_session()
            |> redirect(to: Helpers.bank_path(conn, :index))
            end
            end
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

    def create(conn, %{"account" => account,"email" => email,"provider" => provider}) do
      Socialusermanage.insert_user(account,email,provider)
      socialuser = Socialusermanage |> where([u], u.email == ^email) |> Repo.one()
      if is_nil(socialuser) do
        conn
        |> redirect(to: Helpers.bank_path(conn, :index))
        |> halt()
      else
        conn 
        |>put_session(:user_id,socialuser.id)
        |>put_session(:user_account,socialuser.account)
        |>redirect(to: "/bank/account/#{socialuser.account}/#{socialuser.id}")
      end
    end

    def oauthsignin(conn, %{"account" => account,"email" => email,"provider" => provider}) do
      socialuser = Socialusermanage |> where([u], u.email == ^email) |> Repo.one()
      if is_nil(socialuser) do
          conn
          |> redirect(to: Helpers.bank_path(conn, :index))
          |> halt()
      else
          conn 
          |>put_session(:user_id,socialuser.id)
          |>put_session(:user_account,socialuser.account)
          |>redirect(to: "/bank/account/#{socialuser.account}/#{socialuser.id}")
        end
    end

    defp decode_baseurl64_json(baseurl64) do
      {:ok, json}  = baseurl64 |> Base.url_decode64() 
      {:ok, map}       = json |> JSON.decode()
    end

    #Oauth
    @app_id "197695828014122"
    @app_secret "dd085e5054471410b9fc55fb1fd4de8e"
    @redirect_url "http://localhost:4000/bank/FacebookHandler"
    @facebook_api "https://graph.facebook.com"

    def facebook_login(conn,_params) do
      redirect(conn, external: "https://www.facebook.com/v6.0/dialog/oauth?client_id=#{@app_id}&redirect_uri=#{@redirect_url}&state=#{"{st=state123abc,ds=123456789}"}&auth_type=rerequest&scope=email")
    end

    #exchange code for access token
    def facebook_login_handler(conn, %{"code"=> code}) do

      %{
          "access_token"=> access_token,
          "expires_in"=> expires_in,
          "token_type" => token_type
          } = exchange_access_token(code) # expire : second till expire

      %{
          "app_id" => app_id,
          "application" => application,
          "data_access_expires_at" => data_access_expires_at,
          "expires_at" => expires_at,
          "is_valid" => is_valid,
          "issued_at" => issued_at,
          "scopes" => scope,
          "type" => type,
          "user_id" => user_id
          } = inspect_access_token(access_token)

      %{
          "email"=>email,
          "name"=> name
      } = get_username_email(access_token,user_id)

      socialuser = Repo.get_by(Socialusermanage, email: email)
      if is_nil(socialuser) do
          create(conn, %{"account" => name,"email" => email,"provider" => "facebook"})
      else
          oauthsignin(conn, %{"account" => name,"email" => email,"provider" => "facebook"})
      end

    end

    defp exchange_access_token(code)do
        url = "#{@facebook_api}/v6.0/oauth/access_token?client_id=#{@app_id}&redirect_uri=#{@redirect_url}&client_secret=#{@app_secret}&code=#{code}"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
        json_resp
    end

    defp get_app_access_token() do
        url = "#{@facebook_api}/oauth/access_token?client_id=#{@app_id}&client_secret=#{@app_secret}&grant_type=client_credentials"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
        json_resp["access_token"]
    end

    defp inspect_access_token(access_token) do
        app_access_token = get_app_access_token()
        url = "#{@facebook_api}/debug_token?input_token=#{access_token}&access_token=#{app_access_token}"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
        json_resp["data"]
    end

    defp get_username_email(access_token,user_id) do
        url = "#{@facebook_api}/#{user_id}?fields=name,email&access_token=#{access_token}"
        {:ok, resp} = HTTPoison.get(url)
        {:ok, json_resp} = JSON.decode(resp.body)
        json_resp
    end


end


defmodule HelloWeb.Router do
  use HelloWeb, :router
  

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session # fetch session store, also fetch cookies
    plug :fetch_flash # fetch flash storage
    plug :protect_from_forgery # enable CSRF protection
    plug :put_secure_browser_headers # put headers that improve browser security
    # plug :"Controller.test"
    # plug LearningPlug2, %{}
    # plug :test_assign
    plug HelloWeb.Plugs.SetCurrentUser
    
  end


  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelloWeb do
    pipe_through :browser
    get "/", PageController, :index
  end

  scope "/bank", HelloWeb do
    pipe_through :browser
    get "/",BankController,:index
    get "/signup",BankController, :signup
    get "/signin",BankController, :signin
    post "/signup", BankController, :signuphandler
    post "/signin", BankController, :signinhandler
    get "/account/:name/:id", BankController, :account
    post "/account/:name/:id", BankController, :deposit
    get "/account/:name/:id/transaction", BankController, :transaction
    post "/account/:name/:id/transaction", BankController, :transactionhandler
    #------- Facebook oauth ----------------------------------- 
    get "/LoginWithFacebook",  BankController, :facebook_login
    get "/FacebookHandler"  ,  BankController, :facebook_login_handler
  end
  # Other scopes may use custom stacks.
  scope "/api/bank", HelloWeb do
    pipe_through :api
    get  "/GetAllUsers" ,ApiBankController, :show_all
    post "/Signup"      ,ApiBankController, :create
    post "/Signin"      ,ApiBankController, :signin
    post "/Deposit"     ,ApiBankController, :deposit
    post "/Withdraw"    ,ApiBankController, :withdraw
    post "/Transfer"    ,ApiBankController, :transfer
  end

end


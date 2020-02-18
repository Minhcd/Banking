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
    get "/bank",BankController,:index
    get "/bank/signup",BankController, :signup
    get "/bank/signin",BankController, :signin
    post "/bank/signup", BankController, :signuphandler
    post "/bank/signin", BankController, :signinhandler
    get "/bank/account/:name/:id", BankController, :account
    post "/bank/account/:name/:id", BankController, :deposit
    get "/bank/account/:name/:id/transaction", BankController, :transaction
    post "/bank/account/:name/:id/transaction", BankController, :transactionhandler  
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


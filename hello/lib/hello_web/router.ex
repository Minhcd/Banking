defmodule HelloWeb.Router do
  use HelloWeb, :router
  

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
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
    post "/bank/account/:name/:id", BankController, :withdraw
    
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelloWeb do
  #   pipe_through :api
  # end
end

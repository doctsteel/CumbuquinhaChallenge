defmodule CmbcWeb.Router do
  use CmbcWeb, :router

  scope "/", CmbcWeb do
    # main route to the cumbuca challenge
    post "/", LilDBController, :listener
  end
end

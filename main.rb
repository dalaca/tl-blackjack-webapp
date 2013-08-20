require 'rubygems'
require 'sinatra'

set :sessions, true


get '/' do
	erb :name
end

post '/set_name' do
	session[:player_name] = params[:player_name]
	redirect '/game'
end

get '/game' do
	erb :game
end
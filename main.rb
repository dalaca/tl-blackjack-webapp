require 'rubygems'
require 'sinatra'

set :sessions, true


get '/' do
	'Welcome Dave'
end

get '/name' do
	erb :name
end
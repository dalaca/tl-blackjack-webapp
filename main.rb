require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
	def calculate_total(cards)
		arr = cards.map{|element| element[1]}
		total = 0
		arr.each do |a|
			if a == "A"
				total += 11
			else
				total += a.to_i == 0 ? 10 : a.to_i
			end
		end
		#correct for Aces
		arr.select{|element| element == "A"}.count.times do
			break if total <= 21
			total -= 10
		end
		
		total
	end

	def card_image(card)
	suit = case card[0]
			when 'H' then 'hearts'
			when 'D' then 'diamonds'
			when 'S' then 'spades'
			when 'C' then 'clubs'
		end
	
		if card[1].to_i == 0
			if card[1] == 'K'
				rank = 'king'
			elsif card[1] == 'Q'
				rank = 'queen'
			elsif card[1] == 'J'
				rank = 'jack'
			elsif card[1] == 'A'
				rank = 'ace'
			end
		else
			rank = card[1].to_i
		end
			"<img src='/images/cards/#{suit}_#{rank}.jpg' class='card_image'>"
	end
end

before do
	@show_hit_or_stay_buttons = true
end

get '/' do
	erb :name
end

post '/set_name' do
	if params[:player_name].empty?
		@error = "Name is Required"
		halt erb(:name)
	end

	session[:player_name] = params[:player_name]
	redirect '/game'
end

get '/game' do
	suits = ['H', 'D', 'S', 'C']
	values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
	session[:deck] = suits.product(values).shuffle! 
	session[:player_cards] = []
	session[:dealer_cards] = []
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	
	erb :game
end

post '/game/player/hit' do
	session[:player_cards] << session[:deck].pop
	player_total = calculate_total(session[:player_cards])
	if player_total > 21
		@error = "Sorry, #{session[:player_name]} busted"
		@show_hit_or_stay_buttons = false
	elsif player_total == 21
		@success = "#{session[:player_name]} hit BlackJack!"
		@show_hit_or_stay_buttons = false
	end
	
	erb :game
end

post '/game/player/stay' do
	@success = "#{session[:player_name]} have chosen to stay"
	@show_hit_or_stay_buttons = false
erb :game
end
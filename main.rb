require 'rubygems'
require 'sinatra'

set :sessions, true
BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_POT = 500
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
			break if total <= BLACKJACK_AMOUNT
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

	def winner!(msg)
		@play_again = true
		@success = "<strong> Congratulations #{session[:player_name]}!</strong> #{msg}"
		session[:player_pot] = session[:player_pot] + session[:player_bet].to_i
	end

	def loser!(msg)
		@play_again = true
		@error = "<strong>Sorry #{session[:player_name]},</strong>#{msg}" 
		session[:player_pot] = session[:player_pot] - session[:player_bet].to_i
	end

	def tie!(msg)
		@play_again = true
		@success = "<strong>Meh #{session[:player_name]} Tied!</strong> #{msg}"
		session[:player_pot] = session[:player_pot]
	end
end

before do
	
	@show_hit_or_stay_buttons = true
end

get '/' do
	session[:player_pot] = INITIAL_POT
	erb :name
end

post '/set_name' do
	if params[:player_name].empty?
		@error = "Name is Required"
		halt erb(:name)
	end

	session[:player_name] = params[:player_name]
	redirect '/bet'
end

get '/bet' do
	session[:player_bet] = nil
	erb :set_bet
end

post '/bet' do
	if params[:bet_amount].nil? || params[:bet_amount].to_i == 0 
		@error = "Make a bet"
		halt erb(:set_bet)
	elsif params[:bet_amount].to_i > session[:player_pot]
		@error = " bet amount can't be greater than what you have"
		halt erb(:set_bet)
	else
		session[:player_bet] = params[:bet_amount]
		redirect '/game'
	end
end

get '/game' do
	session[:turn] = session[:player_name]

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
	if player_total > BLACKJACK_AMOUNT
		loser!("busted at #{player_total}")
		@show_hit_or_stay_buttons = false
	elsif player_total == BLACKJACK_AMOUNT
		winner!("Hit BlackJack!")
		@show_hit_or_stay_buttons = false
	end
		
	erb :game
end

post '/game/player/stay' do
	@success = "#{session[:player_name]} have chosen to stay"
	@show_hit_or_stay_buttons = false
	if calculate_total(session[:player_cards]) == BLACKJACK_AMOUNT
		winner!("hit BlackJack!")
	end
redirect '/game/dealer'
end

get '/game/dealer' do
	session[:turn] = "dealer"
	@show_hit_or_stay_buttons = false
	dealer_total = calculate_total(session[:dealer_cards])
	if dealer_total > BLACKJACK_AMOUNT
		winner!("Dealer busted! at #{dealer_total}")
	elsif dealer_total == BLACKJACK_AMOUNT
		loser!("Dealer hit BlackJack")
	elsif dealer_total >= DEALER_MIN_HIT
		#dealer stays
		redirect '/game/compare'
		else 
		@show_dealer_hit_button = true
		#dealer hits
		
	end
	erb :game
end

post '/game/dealer/hit' do
	@show_hit_or_stay_buttons = false
	session[:dealer_cards]<< session[:deck].pop
	redirect '/game/dealer'
end

get '/game/compare' do
	@show_hit_or_stay_buttons = false
player_total = calculate_total(session[:player_cards])
dealer_total = calculate_total(session[:dealer_cards])
	if dealer_total > player_total
		loser!(" #{session[:player_name]} stayed at #{player_total} and dealer had #{dealer_total}, Dealer wins")
	elsif dealer_total < player_total
		winner!(" #{session[:player_name]} stayed at #{player_total} and dealer had #{dealer_total}, you win")
	elsif dealer_total == player_total
		tie!("It's a tie. Both have #{player_total}")
	end
	erb :game
end

get '/game_over' do
	erb :game_over

end
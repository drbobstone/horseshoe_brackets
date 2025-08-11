require 'sinatra'
require 'json'

get '/' do
  send_file 'index.html'
end

post '/randomize' do
  participants = JSON.parse(request.body.read)['participants']
  teams = create_teams(participants)
  bracket = generate_bracket(teams)
  { teams: teams, bracket: bracket }.to_json
end

def create_teams(participants)
  participants.shuffle.each_slice(2).to_a
end

def generate_bracket(teams)
  shuffled_teams = teams.shuffle
  num_teams = shuffled_teams.length
  power_of_2 = 2**Math.log2(num_teams).ceil
  
  winners_bracket = []
  round1_matches = []
  
  num_play_in_matches = num_teams - (power_of_2 / 2)
  num_byes = (power_of_2 / 2) - num_play_in_matches
  
  play_in_teams = shuffled_teams.slice!(0, num_play_in_matches * 2)
  
  (num_play_in_matches).times do
    round1_matches << [play_in_teams.shift, play_in_teams.shift]
  end
  
  shuffled_teams.each do |team|
    round1_matches << [team, 'BYE']
  end
  
  match_counter = 0
  round1_matches_with_ids = round1_matches.shuffle.map do |match|
    { id: ('A'..'Z').to_a[match_counter], teams: match }.tap { match_counter += 1 }
  end
  winners_bracket << round1_matches_with_ids

  num_rounds = Math.log2(power_of_2).to_i
  (num_rounds - 1).times do |i|
    num_matches_in_round = power_of_2 / (2**(i + 2))
    winners_bracket << Array.new(num_matches_in_round) do
      { id: ('A'..'Z').to_a[match_counter], teams: ['TBD', 'TBD'] }.tap { match_counter += 1 }
    end
  end

  losers_bracket = []
  
  # Correctly form the losers bracket
  # There are 2 * (n-1) matches in a double elimination tournament, where n is the number of teams.
  # Winners bracket has n-1 matches. Losers bracket has n-1 matches.
  
  # Losers from winners round 1 drop down.
  wb_round_1_losers = winners_bracket[0].select { |m| m[:teams][1] != 'BYE' }.map { |m| "Loser of #{m[:id]}" }
  
  # The structure of the losers bracket is complex.
  # For now, I will create a placeholder structure that shows all losers from the first round of the winners bracket.
  
  losers_round_1 = []
  wb_round_1_losers.each_slice(2) do |slice|
      match_id = "L" + ('A'..'Z').to_a[match_counter]
      match_counter += 1
      losers_round_1 << { id: match_id, teams: slice }
  end
  losers_bracket << losers_round_1 if losers_round_1.any?
  
  # Grand Final
  grand_final = { id: 'GF', teams: ["Winner of WB", "Winner of LB"] }
  winners_bracket << [grand_final]

  {
    winners_bracket: winners_bracket,
    losers_bracket: losers_bracket
  }
end

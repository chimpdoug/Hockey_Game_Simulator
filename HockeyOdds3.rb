# breaks hockey game into discrete events, checking for score each event
# uses team fenwick to allocate each event to one or other team
# uses team totals to assign probablility of score to each event
# includes pulled goalie when down 1 or 2 in final minute and when down 2 with two minutes to go
# includes sudden death overtime
# for now, 50/50 shootout percentage

puts ""
puts "This program calculates the odds for a hockey game, using parameters you in put for each team,"
puts "plus certain NHL averages. The result is calculated by treating each game as a series of events"
puts "(think of them as scoring chances) with a randomized outcome, and simulating a game of such events"
puts "many times.  It allows for overtime, shootouts (currently treated as coinflips), scoring effects"
puts "(wherein teams that are behind in the game tends to do slightly better in terms of likelihood of"
puts "scoring), home ice advantage, and the pulling of goalies at the end of close games.  It does not"
puts "specifically account for power plays, so when you input parameters for teh strength of the two"
puts "teams you should probably use whole-game values, not just even strength."
puts ""
puts "For a strength parameter for each team, you can use Fenwick percentage (recommended), Corsi,"
puts "shots, goals, or anything else you want.  You'll want one number per team, so something like"
puts "Fenwick percentage will work fine. Note that early in the season these numbers are discounted"
puts "somewhat toward the league average, so we'll also want the number of games the teams have played."
puts "Finally, we'll want goals scored for and against, in order to take account of whether the teams"
puts "are high- or low-scoring."
puts ""
puts "A good source strength values you may want to use is:"
puts "   http://www.extraskater.com/teams/on-ice?sort=team&sit=all&type=total"
puts ""
puts "To begin, what team is at home (city name):"
home_name = gets.chomp
puts "How many games has #{home_name} played (1 - 82)?"
home_games = gets.chomp.to_i
puts "What strength parameter (e.g., should Fenwick rate, shown on that page as FF%) should we use for #{home_name}?"
home_strength = gets.chomp.to_f
puts "How many goals has #{home_name} scored?"
home_goals_for = gets.chomp.to_i
puts "How many goals has #{home_name} allowed?"
home_goals_against = gets.chomp.to_i
home_goals = (home_goals_for + home_goals_against) / home_games
puts ""
puts "OK, what team is the visiting team (city name)?"
away_name = gets.chomp
puts "How many games has #{away_name} played (1 - 82)?"
away_games = gets.chomp.to_i
puts "What strength parameter (e.g., should Fenwick rate, shown on that page as FF%) should we use for #{away_name}?"
away_strength = gets.chomp.to_f
puts "How many goals has #{away_name} scored?"
away_goals_for = gets.chomp.to_i
puts "How many goals has #{away_name} allowed?"
away_goals_against = gets.chomp.to_i
away_goals = (away_goals_for + away_goals_against) / away_games
puts ""
puts "Finally, how many games do you want to simulate? Allow about one second per 20,000 games on an MBP."
iterations = gets.chomp.to_i

start_time = Time.now

puts ""

per_minute = 5 # this is the number of events per minute
regular_tests = per_minute * 58 # a team that is down by 2 will pull its goalie here
down_two_tests = per_minute * 59 # a team that is down by 1 or 2 will pull its goalie here
total_reg_tests = per_minute * 60
ot_tests = per_minute * 5

conf_home_fen = (home_games.to_f / 82) ** 0.5
conf_away_fen = (away_games.to_f / 82) ** 0.5
conf_fen = (conf_home_fen + conf_away_fen) / 2.0
# conf_home_goals = 0.5
conf_home_goals = conf_home_fen
# conf_away_goals = 0.5
conf_away_goals = conf_away_fen

average_goals = 5.42 # league average (from which deviations are assessed)
home_bonus = 0.024 # this estimate of home advantage can be tweaked
behind_bonus = 0.03 # this is the bonus to relative strength for the team that is behind
ot_mult = 1.5 # this is the multiplier for fenwick advantage in overtime, can be tweaked
attacker_bonus = 0.1 #increment to fenwick for a team that has pulled its goalie
empty_mult = 3.0 # overall increase in scoring rate when a net is empty
total_fudge = 0.885 # fudge factor to bring to total down; 0.885 seems to account for all effects well

average_fen = ((((home_strength / away_strength) * conf_fen) + (1 - conf_fen)) / 2) + home_bonus

corrected_home_score = (home_goals * conf_home_goals) + (average_goals * (1 - conf_home_goals))
corrected_away_score = (away_goals * conf_away_goals) + (average_goals * (1 - conf_away_goals))
average_score = (corrected_home_score + corrected_away_score) / 2.0

per_event = average_score / ( 60.0 * per_minute ) * total_fudge

home_reg_wins = 0
home_ot_wins = 0
home_so_wins = 0
away_reg_wins = 0
away_ot_wins = 0
away_so_wins = 0
total_reg = 0
total_ot = 0
total_so = 0
ties = 0
home_by = { -2 => 0,
	-1 => 0,
	1 => 0,
	2 => 0
}
total_dist = { 4 => 0,
	5 => 0,
	6 => 0
}

puts "Running simulations..."
puts""

iterations.times do
	home_goals = 0
	away_goals = 0	
	counter = 0
	
	while counter < total_reg_tests
		# iterate the part of the game before teams will pull their goalies
		if counter < regular_tests
			if per_event > rand 
				if home_goals > away_goals
					if average_fen - behind_bonus > rand # home ahead => away gets bonus
						home_goals += 1
					else
						away_goals += 1
					end
				elsif home_goals < away_goals
					if average_fen + behind_bonus > rand
						home_goals += 1
					else
						away_goals += 1
					end
				else
					if average_fen > rand
						home_goals += 1
					else
						away_goals += 1
					end				
				end
			end
		end
		# iterate the time when teams will pull goalie if down by exactly two
		if (counter >= regular_tests && counter < down_two_tests)
			differential = home_goals - away_goals
			case differential
			 when 2 # home up 2
				if per_event * empty_mult > rand
					if average_fen - attacker_bonus - behind_bonus > rand # home ahead => away gets bonus
						home_goals += 1
					else
						away_goals += 1
					end
				end
			 when -2 # home down 2
				if per_event * empty_mult > rand
					if average_fen + attacker_bonus + behind_bonus > rand # away ahead = home bonus
						home_goals += 1
					else
						away_goals += 1
					end
				end
			 else
				if per_event * empty_mult > rand
					if average_fen > rand
						home_goals += 1
					else
						away_goals += 1
					end
				end
			end
		end
		# iterate the time when teams will pull goalie if down by one or two
		if (counter >= down_two_tests && counter < total_reg_tests)
			differential = home_goals - away_goals
			if (differential == 1 || differential == 2)
				if per_event * empty_mult > rand
					if average_fen - attacker_bonus - behind_bonus > rand  # home ahead = away gets bonus
						home_goals += 1
					else
						away_goals += 1
					end
				end
			elsif (differential == -1 || differential == -2)
				if per_event * empty_mult > rand 
					if average_fen + attacker_bonus + behind_bonus > rand # away ahead = home bonus
						home_goals += 1
					else
						away_goals += 1
					end
				end
			else
				if per_event * empty_mult > rand
					if average_fen > rand
						home_goals += 1
					else
						away_goals += 1
					end
				end
			end	
		end
		counter += 1
	end # end regulation time
	
	if home_goals > away_goals  # home wins in regulation
		home_reg_wins += 1
		total_reg = total_reg + home_goals + away_goals
		if home_goals > away_goals + 1
			home_by[2] += 1
		else
			home_by[1] +=1
		end
		total_goals = home_goals + away_goals
		if total_goals <= 4
			total_dist[4] += 1
		elsif total_goals == 5
			total_dist[5] += 1
		else
			total_dist[6] += 1
		end
		# puts "home won in regulation"
	elsif home_goals < away_goals # away wins in regulation
		away_reg_wins += 1
		total_reg = total_reg + home_goals + away_goals
		if home_goals + 1 < away_goals
			home_by[-2] += 1		
		else
			home_by[-1] +=1
		end
		total_goals = home_goals + away_goals
		if total_goals <= 4
			total_dist[4] += 1
		elsif total_goals == 5
			total_dist[5] += 1
		else
			total_dist[6] += 1		
		end
		# puts "away won in regulation"
	else # play overtime
		ot_counter = 0
		has_ended = 0
		
		while (ot_counter < ot_tests && has_ended == 0)
			if per_event * ot_mult > rand 
				if average_fen > rand
					home_goals += 1
					home_ot_wins += 1
					total_ot += home_goals + away_goals
					has_ended = 1
					home_by[1] += 1
					total_goals = home_goals + away_goals
					case total_goals
					 when 0, 1, 2, 3, 4
					 	total_dist[4] += 1
					 when 5
					 	total_dist[5] += 1
					 else
					 	total_dist[6] += 1
					end
					# puts "home won in overtime"
				else
					away_goals += 1
					away_ot_wins += 1
					total_ot += home_goals + away_goals
					has_ended = 1
					home_by[-1] += 1
					total_goals = home_goals + away_goals
					case total_goals								
					 when 0, 1, 2, 3, 4
					 	total_dist[4] += 1
					 when 5
					 	total_dist[5] += 1
					 else
					 	total_dist[6] += 1				
					end
					# puts "away won in overtime"
				end
			end
			ot_counter +=1
		end
		
		if home_goals == away_goals # shootout after overtime
			if home_goals < 2
				total_dist[4] += 1
			elsif home_goals == 2
				total_dist[5] += 1
			else
				total_dist[6] += 1
			end
			if rand > 0.5 # home shootout win			
				home_so_wins += 1
				home_by[1] += 1	
			else
				away_so_wins += 1
				home_by[-1] += 1
				# puts "away won in a shootout"
			end
			total_so += home_goals + away_goals + 1
		end
	end
end

home_percent = 100.0 * (home_reg_wins + home_ot_wins + home_so_wins.to_f) / iterations
average_total = (total_reg + total_ot + total_so.to_f) / iterations
overtime_percent = 100.0 * (home_ot_wins + away_ot_wins + home_so_wins + away_so_wins.to_f) / iterations
shootout_percent = 100.0 * (home_so_wins + away_so_wins.to_f) / iterations

puts "Final result: home wins #{home_percent}%, total #{average_total}"
puts "#{overtime_percent}% went to overtime; #{shootout_percent}% went to shootout."

home_frac = home_percent / 100.0
away_frac = 1.0 - home_percent

puts ""
puts "Implicit fair odds:"
if home_percent >= 50
	moneyline = (-1) * (home_frac)/(1 - home_frac) * 100
	moneyline = (moneyline + 0.5).floor
	print "  Money line #{home_name} #{moneyline}"
else
	moneyline = (-1) * (away_frac)/(1 - away_frac) * 100
	moneyline = (moneyline + 0.5).floor
	print "  Money line #{away_name} #{moneyline}"
end	

if home_percent >= 50
	puck_line = home_by[2] / iterations.to_f
	if puck_line <= 0.5
		puck_odds = (1 - puck_line) / puck_line * 100
		puck_odds = (puck_odds + 0.5).floor
		puts ", or puck line #{home_name} -1.5 goals +#{puck_odds}"
	else
		puck_odds = puck_line/(1 - puck_line) * -100
		puck_odds = (puck_odds + 0.5).floor
		puts ", or puck line #{away_name} -1.5 goals -#{puck_odds}"
	end
else	
	puck_line = home_by[-2] / iterations.to_f
	if puck_line <= 0.5
		puck_odds = (1 - puck_line) / puck_line * 100
		puck_odds = (puck_odds + 0.5).floor
		puts ", or -1.5 +#{puck_odds}"
	else
		puck_odds = puck_line/(1 - puck_line) * -100
		puck_odds = (puck_odds + 0.5).floor
		puts ", or -1.5 -#{puck_odds}"
	end
end	

under_5 = total_dist[4] / iterations.to_f
at_5 = total_dist[5] / iterations.to_f
over_55 = total_dist[6] / iterations.to_f # for over 5.5
over_5_wager = total_dist[6].to_f / (total_dist[6] + total_dist[4]) # over 5, pushes at 5

if over_5_wager >= 0.5
	odds_over = over_5_wager / (1 - over_5_wager) * -100
	odds_over = (odds_over + 0.5).floor
	print "  Total: over 5 #{odds_over}"
else
	odds_over = (1 - over_5_wager) / over_5_wager * -100
	odds_over = (odds_over + 0.5).floor
	print "  Total: under 5 #{odds_over}"
end

if over_55 >= 0.5
	odds_over = over_55 / (1 - over_55) * -100
	odds_over = (odds_over + 0.5).floor
	puts " or over 5.5 #{odds_over}"
else
	odds_over = (1 - over_55) / over_55 * -100
	odds_over = (odds_over + 0.5).floor
	puts " or under 5.5 #{odds_over}"
end

end_time = Time.now
elapsed = end_time - start_time
puts ""
puts "Elapsed time #{elapsed} seconds for #{iterations} iterations."

puts ""
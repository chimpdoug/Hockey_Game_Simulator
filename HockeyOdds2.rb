# breaks hockey game into discrete events, checking for score each event
# uses team fenwick to allocate each event to one or other team
# uses team totals to assign probablility of score to each event
# includes pulled goalie when down 1 or 2 in final minute and when down 2 with two minutes to go
# includes sudden death overtime
# for now, 50/50 shootout percentage

# for now, test game with Boston at Detroit

# DET = [ fenwick_for_home, fenwick_against_home, goals_for_home, goals_against_home ]
# BOS = [ fenwick_for_away, fenwick_against_away, goals_for_away, goals_against_away ]

start_time = Time.now

puts ""

iterations = 10_000_000
per_minute = 5 # this is the number of events per minute
regular_tests = per_minute * 58 # a team that is down by 2 will pull its goalie here
down_two_tests = per_minute * 59 # a team that is down by 1 or 2 will pull its goalie here
total_reg_tests = per_minute * 60
ot_tests = per_minute * 5

det = [ 30.0, 30.0, 2.75, 2.75 ] # fenwick for, fenwick against, goals for, goals against
bos = [ 30.0, 30.0, 2.75, 2.75 ]

home = det
away = bos
home_name = "Detroit"
away_name = "Boston"

conf_home_fen = 0.6 # a reflection of our confidence that fenwick % deviation from 0 is real
conf_away_fen = 0.6 # use 1.0 to skip the confidence processes
conf_home_goals = 0.5 # raise these confidence numbers as the season goes on
conf_away_goals = 0.5

average_goals = 5.5 # league average (from which deviations are assessed)
home_bonus = 0.022 # this estimate of home advantage can be tweaked
ot_mult = 1.5 # this is the multiplier for fenwick advantage in overtime, can be tweaked
attacker_bonus = 0.1 #increment to fenwick for a team that has pulled its goalie
empty_mult = 3.0 # overall increase in scoring rate when a net is empty
total_fudge = 0.91 # fudge factor to bring to total down; 0.91 seems to account for all effects well


average_home_fen = (home[0] + home[1]) / 2.0
average_away_fen = (away[0] + away[1]) / 2.0
average_home_fen = (average_home_fen * conf_home_fen) + (0.5 * (1 - conf_home_fen))
average_away_fen = (average_away_fen * conf_away_fen) + (0.5 * (1 - conf_away_fen))
average_fen = 0.5 + average_home_fen - average_away_fen + home_bonus

average_home_goals = home[2] + home[3]
average_away_goals = away[2] + away[3]
average_home_goals = (average_home_goals * conf_home_goals) + (average_goals * (1 - conf_home_goals))
average_away_goals = (average_away_goals * conf_away_goals) + (average_goals * (1 - conf_away_goals))
average_score = (average_home_goals + average_away_goals) / 2


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

iterations.times do
	home_goals = 0
	away_goals = 0	
	counter = 0
	
	while counter < total_reg_tests
		# iterate the time before teams will pull their goalies
		if counter < regular_tests
			if per_event > rand 
				if average_fen > rand
					home_goals += 1
				else
					away_goals += 1
				end
			end
			# puts "after #{counter}, the score is #{home_goals} - #{away_goals}"
		end
		# iterate the time when teams will pull goalie if down by exactly two
		if (counter >= regular_tests && counter < down_two_tests)
			differential = home_goals - away_goals
			case differential
			 when 2 # home up 2
				if per_event * empty_mult > rand
					if average_fen - attacker_bonus > rand # home ahead means away gets bonus
						home_goals += 1
					else
						away_goals += 1
					end
				end
			 when -2 # home down 2
				if per_event * empty_mult > rand
					if average_fen + attacker_bonus > rand # away ahead = home bonus
						home_goals += 1
					else
						away_goals += 1
					end
				end
			 else
				if per_event * empty_mult > rand
					if average_fen > rand # away ahead = home bonus
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
					if average_fen - attacker_bonus > rand  # home ahead = away gets bonus
						home_goals += 1
					else
						away_goals += 1
					end
				end
			elsif (differential == -1 || differential == -2)
				if per_event * empty_mult > rand 
					if average_fen + attacker_bonus > rand # away ahead = home bonus
						home_goals += 1
					else
						away_goals += 1
					end
				end
			else
				if per_event * empty_mult > rand
					if average_fen > rand # away ahead = home bonus
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

home_percent = 100 * (home_reg_wins + home_ot_wins + home_so_wins.to_f) / iterations
average_total = (total_reg + total_ot + total_so.to_f) / iterations
overtime_percent = 100 * (home_ot_wins + away_ot_wins + home_so_wins + away_so_wins.to_f) / iterations
shootout_percent = 100 * (home_so_wins + away_so_wins.to_f) / iterations

puts "Final result: home wins #{home_percent}%, total #{average_total}"
puts "#{overtime_percent}% went to overtime; #{shootout_percent}% went to shootout."

home_frac = home_percent / 100.0
away_frac = 1.0 - home_percent

puts ""
puts "Implicit fair odds:"
if home_percent >= 0.5
	moneyline = (-1) * (home_frac)/(1 - home_frac) * 100
	moneyline = (moneyline + 0.5).floor
	print "  #{home_name} #{moneyline}"
else
	moneyline = (-1) * (away_frac)/(1 - away_frac) * 100
	moneyline = (moneyline + 0.5).floor
	print "  #{away_name} #{moneyline}"
end	

if home_percent >= 0.5
	puck_line = home_by[2] / iterations.to_f
	if puck_line <= 0.5
		puck_odds = (1 - puck_line) / puck_line * 100
		puck_odds = (puck_odds + 0.5).floor
		puts ", or -1.5 +#{puck_odds}"
	else
		puck_odds = puck_line/(1 - puck_line) * -100
		puck_odds = (puck_odds + 0.5).floor
		puts ", or -1.5 -#{puck_odds}"
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
	print "  Total: under 5 +#{odds_over}"
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

# puts home_by
# puts total_dist

# puts ""

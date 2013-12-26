#!/usr/bin/env ruby

# Breaks hockey game into discrete events, checking for score each
# event uses team fenwick to allocate each event to one or other team
# uses team totals to assign probablility of score to each event
# includes pulled goalie when down 1 or 2 in final minute and when
# down 2 with two minutes to go includes sudden death overtime for
# now, 50/50 shootout percentage

# Grab stuff from the Ruby standard library.
require 'open-uri'

# Grab stuff from Gems.
begin 
  require 'nokogiri'
rescue LoadError => e
  abort "Please install the following gem: " + e.message.split('--').last.strip
end

# The URL that we pull the source data from.
EXTRA_SKATER_URL = "http://www.extraskater.com/teams/on-ice?sort=team&sit=all&type=total"

# The names of the fields for each team.
FIELDS = %w[GP TOI GF GA GF% CF CA CF% FF FA FF% SF SA SF% Sh% Sv% PDO]

# Stores the data we obtain from the source.
TEAMS = {}

# Main method which runs the program.
def run
  fetch_data
  choose_home_team
  choose_away_team
  simulate
  print_results
end

# Fetches data from the EXTRA_SKATER_URL and parses it into the TEAMS
# hash.
def fetch_data
  website = open(EXTRA_SKATER_URL)
  Nokogiri::HTML::Document.parse(website).css('tr').each do |tr| # grab every 'tr' element
    row     = tr.css('td').map(&:inner_text)                     # turn each 'tr' into a row (Array of String)
    values  = (parse_row(row) or next)                           # parse each row into a Hash of named values
    TEAMS[values.delete(:index)] = values                        # add each Hash to the TEAMS data
  end
end

# Parses a single row of data from the table at the source.
#
# @param [Array<String>] row
# @return [Hash]
def parse_row row
  return unless row.size == 19  # ignores header row
  data = {}
  data[:index] = row.shift.to_i
  data[:name]  = row.shift
  row.map! do |value|
    case value
    when value.include?('%') then value.to_f / 100.0
    when value.include?('.') then value.to_f
    else
      value.to_i
    end
  end
  data.merge(Hash[FIELDS.zip(row)])
end

def choose_home_team
  print_choices
end

def print_choices
  puts "Please choose a team (using its number):"
  puts ""
  TEAMS.each_pair do |index, team|
    puts "#{index}\t#{team[:name]}"
  end
  puts ""
end

def choose_away_team
  print_choices
end

def simulate
end

def print_results
end

#
# Run the main method.
#

run if $0 == __FILE__

# Description:
#   Make hubot fetch the national felony football scores
#
# Dependencies:
#   "scraper": "0.0.9"
#
# Configuration:
#   None
#
# Commands:
#   felony football scoreboard
# Author:
#   jbavari

cheerio = require 'cheerio'
$ = null
teams = {}

# teams = { '2014': { 'DAL': 1 }, '2013': { 'DAL': 3 } }

# item is <tr> element. 1st child is date, 2nd is team short name
getTeamCounts = (index, item) ->
  # console.log('index: ', index, ' item: ', item)
  year = $(item).find('td:nth-child(1)').html().substring(0, 4)
  # console.log('year: ', year)
  if typeof teams[year] == 'undefined'
    teams[year] = {}

  teamAtr = $(item).find('td:nth-child(2)').html()
  # console.log('teamAtr: ', teamAtr)
  teamCount = teams[year][teamAtr]
  # console.log('team count: ', teamCount)

  if typeof teamCount == 'undefined'
    teams[year][teamAtr] = 1;
    # console.log('initing team count ' , teamAtr)
  else
    teamCount = teamCount + 1
    # console.log('added 1 to team count for ', teamAtr)
    teams[year][teamAtr] = teamCount

retrieveTeamScores = (robot, callback) ->
  robot.http('http://www.usatoday.com/sports/nfl/arrests/')
    .get() (err, res, body) ->
      $ = cheerio.load(body)
      # console.log('jquery : ' , $)
      throw err if err
      # $('tbody tr').remove()
      # $('tbody tr td:nth-child(2)').each(getTeamCounts)
      $('tbody tr').each(getTeamCounts)
      # msg.send JSON.stringify(teams)
      callback(teams)

getTeamDetails = (index, item) ->
  team = $(item).find('td:nth-child(2)').html()
  
  if typeof teams[team] == 'undefined'
    teams[team] = []

  date = $(item).find('td:nth-child(1)').html()
  name = $(item).find('td:nth-child(3)').html()
  teams[team].push("#{date} - #{name}")

retrieveTeamDetails = (robot, callback) ->
  robot.http('http://www.usatoday.com/sports/nfl/arrests/')
    .get() (err, res, body) ->
      throw err if err
      $ = cheerio.load(body)

      $('tbody tr').each(getTeamDetails)
      callback(teams)

format = (data, team) ->
  rank = []
  deets = []
  for key of data
    rank.push { team: key, num: data[key] } if not team? or key.localeCompare(team) == 0
  rank.sort(orderByDesc)
  deets.push " * #{t.team} - #{t.num}" for t in rank
  deets.push " * No arrests for #{team}, yet." if team? and deets.length == 0
  deets.join '\n'

orderByDesc = (a,b) ->
  b.num - a.num

formatTeamByYear = (data, team) ->
  rank = []
  deets = []
  for year of data
    yrData = data[year]
    for key of yrData
      rank.push { year: year, num: yrData[key] } if key.localeCompare(team) == 0
  
  rank.sort(orderByYearDesc)
  deets.push " * #{t.year} - #{t.num}" for t in rank
  deets.push " * No arrests for #{team}, yet." if team? and deets.length == 0
  deets.join '\n'

orderByYearDesc = (a,b) ->
  b.year - a.year

formatTeamDetails = (data, team) ->
  deets = []
  deets.push " * #{t}" for t in data[team]
  deets.push " * No arrests for #{team}, yet." if team? and deets.length == 0
  deets.join '\n'

module.exports = (robot) ->

  robot.hear /felony football/i, (msg) ->
    teams = {}
    sendMessage = (data) ->
      msg.send JSON.stringify(data)
    retrieveTeamScores(robot, sendMessage)

  robot.respond /nffl (\d{4})(\s)?(.*)?/i, (msg) ->
    teams = {}
    year = msg.match[1] or null
    team = msg.match[3] or null

    sendMessage = (data) ->
      output = "NFFL - #{year}"
      team = team.toUpperCase() if team?
      output += " #{team}" if team?
      yearScores = data[year]
      output += '\n' + format yearScores, team
      msg.send output

    retrieveTeamScores(robot, sendMessage)

  robot.respond /nffl team(\s)?(.*)?/i, (msg) ->
    teams = {}
    team = msg.match[2] or null

    sendMessage = (data) ->
      team = team.toUpperCase() if team?
      output = "NFFL - #{team}"
      output += '\n' + formatTeamByYear data, team
      msg.send output

    retrieveTeamScores(robot, sendMessage)

  robot.respond /nffl details(\s)?(.*)?/i, (msg) ->
    teams = {}
    team = msg.match[2] or null

    sendMessage = (data) ->
      team = team.toUpperCase() if team?
      output = "NFFL - Details for #{team}"
      output += '\n' + formatTeamDetails data, team
      msg.send output

    retrieveTeamDetails(robot, sendMessage)
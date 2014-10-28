# Description:
#   Make hubot fetch the national felony football scores
#
# Dependencies:
#   "cheerio": "^0.17.0"
#
# Configuration:
#   None
#
# Commands:
#   felony football - return arrest scorecard
#   hubot nffl - return arrest scorecard
#   hubot nffl <year> - show nfl arrests for the given year
#   hubot nffl <year> <team> - show nfl arrests for the given year, by team
#   hubot nffl team <team> - show nfl arrests for the team
#   hubot nffl details <team> - show nfl arrests for the team with player details
#   hubot nffl help - show list of hubot nffl commands
#   hubot nffl info - show some simple info about this script
#
# Author:
#   jbavari, ryoe

cheerio = require 'cheerio'
url = 'http://www.usatoday.com/sports/nfl/arrests/'
$ = null
teams = {}
help = [
  'felony football - return arrest scorecard'
  'hubot nffl - return arrest scorecard'
  'hubot nffl <year> - show nfl arrests for the given year'
  'hubot nffl <year> <team> - show nfl arrests for the given year, by team'
  'hubot nffl team <team> - show nfl arrests for the team'
  'hubot nffl details <team> - show nfl arrests for the team with player details'
  'hubot nffl help - show list of hubot nffl commands'
  'hubot nffl info - show some simple info about this script'
]

#hat tip to David Pearson https://github.com/NFLScoreBot/nfl-teams
nflTeams =
  "Arizona Cardinals"    : { alt: ["cardinals", "cards", "zona", "az"], abbr: "ARI" }
  "Atlanta Falcons"      : { alt: ["falcons", "atlanta"], abbr: "ATL" }
  "Baltimore Ravens"     : { alt: ["ravens", "baltimore"], abbr: "BAL" }
  "Buffalo Bills"        : { alt: ["bills", "buffalo"], abbr: "BUF" }
  "Carolina Panthers"    : { alt: ["panthers", "carolina"], abbr: "CAR" }
  "Chicago Bears"        : { alt: ["bears", "da bears", "chicago"], abbr: "CHI" }
  "Cincinnati Bengals"   : { alt: ["bengals", "cincinnati", "cincy"], abbr: "CIN" }
  "Cleveland Browns"     : { alt: ["browns", "cleveland"], abbr: "CLE" }
  "Dallas Cowboys"       : { alt: ["cowboys", "boys", "americas team", "america's team", "dallas"], abbr: "DAL" }
  "Denver Broncos"       : { alt: ["broncos", "broncs", "bronchos", "denver"], abbr: "DEN" }
  "Detroit Lions"        : { alt: ["lions", "detroit"], abbr: "DET" }
  "Green Bay Packers"    : { alt: ["packers", "pack", "green and gold", "cheese heads", "cheeseheads", "green bay"], abbr: "GB" }
  "Houston Texans"       : { alt: ["texans", "texans"], abbr: "HOU" }
  "Indianapolis Colts"   : { alt: ["colts", "indy", "indianapolis"], abbr: "IND" }
  "Jacksonville Jaguars" : { alt: ["jaguars", "jags", "jacksonville"], abbr: "JAC" }
  "Kansas City Chiefs"   : { alt: ["chiefs", "kansas city"], abbr: "KC" }
  "Miami Dolphins"       : { alt: ["dolphins", "fins", "miami"], abbr: "MIA" }
  "Minnesota Vikings"    : { alt: ["vikings", "vikes", "minny", "minnesota"], abbr: "MIN" }
  "New England Patriots" : { alt: ["patriots", "pats", "new england"], abbr: "NE" }
  "New Orleans Saints"   : { alt: ["saints", "who dat", "who dat?", "orleans", "new orleans"], abbr: "NO" }
  "New York Giants"      : { alt: ["giants", "big blue", "gmen"], abbr: "NYG" }
  "New York Jets"        : { alt: ["jets", "gang green"], abbr: "NYJ" }
  "Oakland Raiders"      : { alt: ["raiders", "silver and black"], abbr: "OAK" }
  "Pittsburgh Steelers"  : { alt: ["steelers", "stillers", "stihllers", "pgh", "pitt", "pittsburgh"], abbr: "PIT" }
  "Philadelphia Eagles"  : { alt: ["eagles", "philly", "philadelphia"], abbr: "PHI" }
  "San Diego Chargers"   : { alt: ["chargers", "bolts", "superchargers", "san diego superchargers", "san diego"], abbr: "SD" }
  "San Francisco 49ers"  : { alt: ["49ers", "niners", "san fran", "san francisco"], abbr: "SF" }
  "Seattle Seahawks"     : { alt: ["seahawks", "hawks", "seattle"], abbr: "SEA" }
  "Tampa Bay Buccaneers" : { alt: ["buccaneers", "bucs", "tampa", "tampa bay"], abbr: "TB" }
  "St. Louis Rams"       : { alt: ["rams", "st. louis"], abbr: "STL" }
  "Tennessee Titans"     : { alt: ["titans", "tenn", "tennessee"], abbr: "TEN" }
  "Washington Redskins"  : { alt: ["redskins", "skins", "wash", "washington"], abbr: "WAS" }

findTeamName = (name) ->
  if name == null
    return null
  team = nflTeams[name] or null
  if team?
    return name
  for t of nflTeams
    if t.toLowerCase().localeCompare(name.toLowerCase()) == 0
      return t
    team = nflTeams[t]
    if team.abbr.localeCompare(name.toUpperCase()) == 0
      return t
    for nick in team.alt
      console.log nick
      console.log name
      console.log nick.localeCompare(name.toLowerCase())
      if nick.localeCompare(name.toLowerCase()) == 0
        return t
  return null

findTeamAbbr = (name) ->
  if name == null
    return null
  teamName = findTeamName name
  if not teamName?
    return null
  return nflTeams[teamName].abbr

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

retrieveTeamScores = (msg, callback) ->
  msg.http(url)
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
  robot.http(url)
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

formatAll = (data) ->
  deets = []
  yearDeets = []
  for year of data
    yearDeets.push { year: year, data: data[year] }

  yearDeets.sort(orderByYearDesc)
  deets.push "#{deet.year}\n" + format(deet.data) for deet in yearDeets
  deets.join '\n\n'

showAll = (msg) ->
  teams = {}
  sendMessage = (data) ->
    output = "NFFL - All Years\n"
    output += formatAll data
    msg.send output
  retrieveTeamScores(msg, sendMessage)

module.exports = (robot) ->

  robot.hear /felony football/i, (msg) ->
    showAll msg

  robot.respond /nffl help/i, (msg) ->
    msg.send help.join '\n'

  robot.respond /nffl info/i, (msg) ->
    deets = [
      "felony-football.coffee brought to you by jbavari"
      "NFL Arrest data from #{url}"
    ]
    msg.send deets.join '\n'

  robot.respond /nffl(\s)?(\d{4})?(\s)?(.*){0,}/i, (msg) ->
    reIgnore = /help|info|^team&|details/gi
    teams = {}
    year = msg.match[2] or null
    team = msg.match[4] or null

    if team?
      #exit if early if we match commands handled elsewhere
      return if reIgnore.test team

    if not year? and team?
      msg.send 'Unknown command. Try "hubot nffl help".'
      return

    if not year?
      showAll msg
      return

    teamName = findTeamName team
    teamAbbr = findTeamAbbr teamName

    if not teamName? and team?
      msg.send "Unknown team '#{team}'. :("
      return

    sendMessage = (data) ->
      output = "NFFL - #{year}"
      output += " #{teamName}" if teamName?
      yearScores = data[year]
      output += '\n' + format yearScores, teamAbbr
      msg.send output

    if year?
      retrieveTeamScores(msg, sendMessage)

  robot.respond /nffl team(\s)?(.*){1,}/i, (msg) ->
    teams = {}
    team = msg.match[2] or null

    if not team?
      msg.send 'Did you mean "hubot nffl team <team>"?'
      return

    teamName = findTeamName team
    teamAbbr = findTeamAbbr teamName
    if not teamName?
      msg.send "Unknown team '#{team}'. :("
      return

    sendMessage = (data) ->
      output = "NFFL - #{teamName}"
      output += '\n' + formatTeamByYear data, teamAbbr
      msg.send output

    retrieveTeamScores(robot, sendMessage)

  robot.respond /nffl details(\s)?(.*){1,}/i, (msg) ->
    teams = {}
    team = msg.match[2] or null

    if not team?
      msg.send 'Did you mean "hubot nffl details <team>"?'
      return

    teamName = findTeamName team
    teamAbbr = findTeamAbbr teamName
    if not teamName?
      msg.send "Unknown team '#{team}'. :("
      return

    sendMessage = (data) ->
      output = "NFFL - Details for #{teamName}"
      output += '\n' + formatTeamDetails data, teamAbbr
      msg.send output

    retrieveTeamDetails(robot, sendMessage)
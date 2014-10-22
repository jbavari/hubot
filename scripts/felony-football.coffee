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

format = (data) ->
  rank = []
  deets = []
  for key of data
    rank.push { team: key, num: data[key]}
  rank.sort(orderByDesc)
  deets.push "#{t.team} - #{t.num}" for t in rank
  deets.join '\n'

orderByDesc = (a,b) ->
  b.num - a.num

module.exports = (robot) ->

  robot.hear /felony football/i, (msg) ->
    teams = {}
    sendMessage = (data) ->
      msg.send JSON.stringify(data)
    retrieveTeamScores(robot, sendMessage)

  robot.respond /nffl (\d{4})/i, (msg) ->
    teams = {}
    year = msg.match[1] or null
    
    sendMessage = (data) ->
      yearScores = data[year]
      output = format yearScores
      msg.send output

    retrieveTeamScores(robot, sendMessage)

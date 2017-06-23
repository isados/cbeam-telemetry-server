cbeam = require './cbeam'
express = require 'express'
ws = require 'ws'

class Server
  histories: {}
  listeners: []
  constructor: (@config) ->
    @app = express()

    @app.use express.static 'assets'
    @app.use '/node_modules/openmct', express.static 'node_modules/openmct'
    @app.get '/dictionary/:dict.json', (req, res) =>
      for dict in @config.dictionaries
        if dict.key is req.params.dict
          res.json dict.toJSON()
          return
      res.status(404).end()
    @app.get '/telemetry/:pointId', (req, res) =>
      start = parseInt req.query.start
      end = parseInt req.query.end
      ids = req.params.pointId.split ','
      console.log ids
      histories = @histories
      response = ids.reduce (resp, id) ->
        histories[id] = [] unless histories[id]
        resp.concat histories[id].filter (p) ->
          p.timestamp > start and p.timestamp < end
      , []
      res.json response
      return

  start: (callback) ->
    @wss = new ws.Server
      port: @config.wss_port
    @app.listen @config.port, (err) =>
      return callback err if err
      cbeam.connect (err, client) =>
        return callback err if err
        @cbeam = client
        callback null

exports.handleConnection = (server, socket) ->
  # Topics subscribed by this connection
  subscriptions = {}

  handlers =
    dictionary: ->
      socket.send JSON.stringify
        type: 'dictionary'
        value: server.dictionary
    subscribe: (id) ->
      subscriptions[id] = true
    unsubscribe: (id) ->
      delete subscriptions[id]
    history: (id) ->
      socket.send JSON.stringify
        type: 'history'
        id: id
        value: server.histories[id]

  notify = ->
    for id, value of subscriptions
      history = server.histories[id]
      continue unless history
      socket.send JSON.stringify
        type: 'data'
        id: id
        value: history[history.length - 1]

  # Listen for requests
  socket.on 'message', (message) ->
    parts = message.split ' '
    handler = handlers[parts[0]]
    unless handler
      console.log "No handler for #{parts[0]}"
      return
    handler.apply handlers, parts.slice 1

  # Remove subscription when connection closes
  socket.on 'close', ->
    server.listeners = server.listeners.filter (l) ->
      l isnt notify

  # Register listener
  server.listeners.push notify

main = (config) ->
  exports.initialize config, (err, server) ->
    if err
      console.error err
      process.exit 1
    console.log "c-beam telemetry server running on port #{config.port}"
    console.log "c-beam telemetry provider running on port #{config.wss_port}"
    console.log "Open c-beam telemetry server at http://#{config.host}:#{config.port}"

    # Subscribe to all messages
    server.cbeam.subscribe '#'
    server.cbeam.on 'message', (topic, msg) ->
      messages = cbeam.filterMessages topic, msg, server.dictionary
      return unless messages.length
      for msg in messages
        server.histories[msg.id] = [] unless server.histories[msg.id]
        server.histories[msg.id].push
          timestamp: Date.now()
          value: msg.value
      server.listeners.forEach (listener) ->
        do listener
    server.wss.on 'connection', (socket) ->
      exports.handleConnection server, socket

module.exports = Server

module.exports = (env) ->

# Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  {Sonos} = require 'sonos'

  Promise.promisifyAll(Sonos.prototype);

  class SonosPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("SonosPlayer", {
        configDef: deviceConfigDef.SonosPlayer,
        createCallback: (config) -> new SonosPlayer(config)
      })

  class SonosPlayer extends env.devices.Device

    _state: null
    _currentTitle: null
    _currentArtist: null
    _volume: null

    actions:
      play:
        description: "starts playing"
      pause:
        description: "pauses playing"
      stop:
        description: "stops playing"
      next:
        description: "play next song"
      previous:
        description: "play previous song"
      volume:
        description: "Change volume of player"

    attributes:
      currentArtist:
        description: "the current playing track artist"
        type: "string"
      currentTitle:
        description: "the current playing track title"
        type: "string"
      state:
        description: "the current state of the player"
        type: "string"
      volume:
        description: "the volume of the player"
        type: "string"

    template: "musicplayer"

    constructor: (@config) ->
      @name = config.name
      @id = config.id

      @_sonosClient = new Sonos(config.host, config.port)

      @_updateInfo()
      setInterval( ( => @_updateInfo() ), @config.interval)

      super()

    getState: () ->
      return Promise.resolve @_state

    getCurrentTitle: () -> Promise.resolve(@_currentTitle)
    getCurrentArtist: () -> Promise.resolve(@_currentTitle)
    getVolume: ()  -> Promise.resolve(@_volume)

    play:() -> @_sonosClient.playAsync().then((state) => @_setState(state))

    pause:() -> @_sonosClient.pauseAsync().then((state) => @_setState(state))

    stop:() -> @_sonosClient.stopAsync().then((state)  => @_setState(state))

    next:() -> @_sonosClient.nextAsync().then(()  => @_getCurrentSong())

    previous:() -> @_sonosClient.previousAsync().then(()  => @_getCurrentSong())

    setVolume: (volume) -> @_sonosClient.setVolumeAsync(volume).then((volume)  => @_setVolume(volume))

    _updateInfo: -> Promise.all([@_getStatus(), @_getVolume, @_getCurrentSong()])

    _setState: (state) ->
      if @_state isnt state
        @_state = state
        @emit 'state', state

    _setCurrentTitle: (title) ->
      if @_currentTitle isnt title
        @_currentTitle = title
        @emit 'currentTitle', title

    _setCurrentArtist: (artist) ->
      if @_currentArtist isnt artist
        @_currentArtist = artist
        @emit 'currentArtist', artist

    _setVolume: (volume) ->
      if @_volume isnt volume
        @_volume = volume
        @emit 'volume', volume

    _getStatus: () ->
      @_sonosClient.getCurrentStateAsync().then( (state) =>
        @_setState(state)
      )

    _getVolume: () ->
      @_sonosClient.getVolumeAsync().then( (volume) =>
        @_setVolume(volume)
      )

    _getCurrentSong: () ->
      @_sonosClient.currentTrackAsync().then( (info) =>
        @_setCurrentArtist(info.artist)
        @_setCurrentTitle(info.title)
      )


  sonosPlugin = new SonosPlugin
  return sonosPlugin
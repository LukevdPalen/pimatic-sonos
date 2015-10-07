module.exports = (env) ->

# Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  M = env.matcher
  _ = env.require('lodash')

  {Sonos} = require 'sonos'

  Promise.promisifyAll(Sonos.prototype) ;

  class SonosPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("SonosPlayer", {
        configDef: deviceConfigDef.SonosPlayer,
        createCallback: (config) -> new SonosPlayer(config)
      } )

      @framework.ruleManager.addActionProvider(new SonosPauseActionProvider(@framework) )
      @framework.ruleManager.addActionProvider(new SonosPlayActionProvider(@framework) )
      @framework.ruleManager.addActionProvider(new SonosVolumeActionProvider(@framework) )
      @framework.ruleManager.addActionProvider(new SonosPrevActionProvider(@framework) )
      @framework.ruleManager.addActionProvider(new SonosNextActionProvider(@framework) )


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
    getVolume: () -> Promise.resolve(@_volume)

    play: () -> @_sonosClient.playAsync().then((state) => @_setState(state) )

    pause: () -> @_sonosClient.pauseAsync().then((state) => @_setState(state) )

    stop: () -> @_sonosClient.stopAsync().then((state) => @_setState(state) )

    next: () -> @_sonosClient.nextAsync().then(() => @_getCurrentSong() )

    previous: () -> @_sonosClient.previousAsync().then(() => @_getCurrentSong() )

    setVolume: (volume) -> @_sonosClient.setVolumeAsync(volume).then((volume) => @_setVolume(volume) )

    _updateInfo: -> Promise.all([@_getStatus(), @_getVolume(), @_getCurrentSong() ])

    _setState: (state) ->
      switch state
        when 'playing' then state = 'play'
        when 'paused' then state = 'pause'
        when 'stopped' then state = 'stop'
        else state = 'unknown'

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

  # Pause play volume actions
  class SonosPauseActionProvider extends env.actions.ActionProvider

    constructor: (@framework) ->
# ### executeAction()
      ###
      This function handles action in the form of `execute "some string"`
      ###
    parseAction: (input, context) =>

      retVar = null

      sonosPlayers = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("play")
      ).value()

      if sonosPlayers.length is 0 then return

      device = null
      match = null

      onDeviceMatch = ( (m, d) -> device = d; match = m.getFullMatch() )

      m = M(input, context)
      .match('pause ')
      .matchDevice(sonosPlayers, onDeviceMatch)

      if match?
        assert device?
        assert typeof match is "string"
        return {
        token: match
        nextInput: input.substring(match.length)
        actionHandler: new SonosPauseActionHandler(device)
        }
      else
        return null

  class SonosPauseActionHandler extends env.actions.ActionHandler

    constructor: (@device) -> #nop

    executeAction: (simulate) =>
      return (
        if simulate
          Promise.resolve __("would pause %s", @device.name)
        else
          @device.pause().then( => __("paused %s", @device.name) )
      )

  # stop play volume actions
  class MpdStopActionProvider extends env.actions.ActionProvider

    constructor: (@framework) ->
# ### executeAction()
      ###
      This function handles action in the form of `execute "some string"`
      ###
    parseAction: (input, context) =>

      retVar = null

      sonosPlayers = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("play")
      ).value()

      if sonosPlayers.length is 0 then return

      device = null
      match = null

      onDeviceMatch = ( (m, d) -> device = d; match = m.getFullMatch() )

      m = M(input, context)
      .match('stop ')
      .matchDevice(sonosPlayers, onDeviceMatch)

      if match?
        assert device?
        assert typeof match is "string"
        return {
        token: match
        nextInput: input.substring(match.length)
        actionHandler: new MpdStopActionHandler(device)
        }
      else
        return null

  class MpdStopActionHandler extends env.actions.ActionHandler

    constructor: (@device) -> #nop

    executeAction: (simulate) =>
      return (
        if simulate
          Promise.resolve __("would stop %s", @device.name)
        else
          @device.stop().then( => __("stop %s", @device.name) )
      )

  class SonosPlayActionProvider extends env.actions.ActionProvider

    constructor: (@framework) ->
# ### executeAction()
      ###
      This function handles action in the form of `execute "some string"`
      ###
    parseAction: (input, context) =>

      retVar = null

      sonosPlayers = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("play")
      ).value()

      if sonosPlayers.length is 0 then return

      device = null
      match = null

      onDeviceMatch = ( (m, d) -> device = d; match = m.getFullMatch() )

      m = M(input, context)
      .match('play ')
      .matchDevice(sonosPlayers, onDeviceMatch)

      if match?
        assert device?
        assert typeof match is "string"
        return {
        token: match
        nextInput: input.substring(match.length)
        actionHandler: new MpdPlayActionHandler(device)
        }
      else
        return null

  class MpdPlayActionHandler extends env.actions.ActionHandler

    constructor: (@device) -> #nop

    executeAction: (simulate) =>
      return (
        if simulate
          Promise.resolve __("would play %s", @device.name)
        else
          @device.play().then( => __("playing %s", @device.name) )
      )

  class SonosVolumeActionProvider extends env.actions.ActionProvider

    constructor: (@framework) ->
# ### executeAction()
      ###
      This function handles action in the form of `execute "some string"`
      ###
    parseAction: (input, context) =>

      retVar = null
      volume = null

      sonosPlayers = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("play")
      ).value()

      if sonosPlayers.length is 0 then return

      device = null
      valueTokens = null
      match = null

      onDeviceMatch = ( (m, d) -> device = d; match = m.getFullMatch() )

      M(input, context)
      .match('change volume of ')
      .matchDevice(sonosPlayers, (next, d) =>
        next.match(' to ', (next) =>
          next.matchNumericExpression( (next, ts) =>
            m = next.match('%', optional: yes)
            if device? and device.id isnt d.id
              context? .addError(""""#{input.trim()}" is ambiguous.""")
              return
            device = d
            valueTokens = ts
            match = m.getFullMatch()
          )
        )
      )


      if match?
        value = valueTokens[0]
        assert device?
        assert typeof match is "string"
        value = parseFloat(value)
        if value < 0.0
          context? .addError("Can't dim to a negativ dimlevel.")
          return
        if value > 100.0
          context? .addError("Can't dim to greaer than 100%.")
          return
        return {
        token: match
        nextInput: input.substring(match.length)
        actionHandler: new MpdVolumeActionHandler(@framework, device, valueTokens)
        }
      else
        return null

  class MpdVolumeActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @device, @valueTokens) -> #nop

    executeAction: (simulate, value) =>
      return (
        if isNaN(@valueTokens[0])
          val = @framework.variableManager.getVariableValue(@valueTokens[0].substring(1) )
        else
          val = @valueTokens[0]
        if simulate
          Promise.resolve __("would set volume of %s to %s", @device.name, val)
        else
          @device.setVolume(val).then( => __("set volume of %s to %s", @device.name, val) )
      )

  class SonosNextActionProvider extends env.actions.ActionProvider

    constructor: (@framework) ->
# ### executeAction()
      ###
      This function handles action in the form of `execute "some string"`
      ###
    parseAction: (input, context) =>

      retVar = null
      volume = null

      sonosPlayers = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("play")
      ).value()

      if sonosPlayers.length is 0 then return

      device = null
      valueTokens = null
      match = null

      onDeviceMatch = ( (m, d) -> device = d; match = m.getFullMatch() )

      m = M(input, context)
      .match(['play next', 'next '])
      .match(" song ", optional: yes)
      .matchDevice(sonosPlayers, onDeviceMatch)

      if match?
        assert device?
        assert typeof match is "string"
        return {
        token: match
        nextInput: input.substring(match.length)
        actionHandler: new SonosNextActionHandler(device)
        }
      else
        return null

  class SonosNextActionHandler extends env.actions.ActionHandler
    constructor: (@device) -> #nop

    executeAction: (simulate) =>
      return (
        if simulate
          Promise.resolve __("would play next track of %s", @device.name)
        else
          @device.next().then( => __("play next track of %s", @device.name) )
      )

  class SonosPrevActionProvider extends env.actions.ActionProvider

    constructor: (@framework) ->
# ### executeAction()
      ###
      This function handles action in the form of `execute "some string"`
      ###
    parseAction: (input, context) =>

      retVar = null
      volume = null

      sonosPlayers = _(@framework.deviceManager.devices).values().filter(
        (device) => device.hasAction("play")
      ).value()

      if sonosPlayers.length is 0 then return

      device = null
      valueTokens = null
      match = null

      onDeviceMatch = ( (m, d) -> device = d; match = m.getFullMatch() )

      m = M(input, context)
      .match(['play previous', 'previous '])
      .match(" song ", optional: yes)
      .matchDevice(sonosPlayers, onDeviceMatch)

      if match?
        assert device?
        assert typeof match is "string"
        return {
        token: match
        nextInput: input.substring(match.length)
        actionHandler: new SonosNextActionHandler(device)
        }
      else
        return null

  class MpdPrevActionHandler extends env.actions.ActionHandler
    constructor: (@device) -> #nop

    executeAction: (simulate) =>
      return (
        if simulate
          Promise.resolve __("would play previous track of %s", @device.name)
        else
          @device.previous().then( => __("play previous track of %s", @device.name) )
      )


  sonosPlugin = new SonosPlugin

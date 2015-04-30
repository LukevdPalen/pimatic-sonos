module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  Sonos = require 'Sonos'

  class SonosPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("SonosPlayer", {
        configDef: deviceConfigDef.SonosPlayer,
        createCallback: (config, lastState) ->
          device = new SonosPlayer(config, lastState)
          return device
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

		@sonosClient = new Sonos(config.host, config.port || 1400)
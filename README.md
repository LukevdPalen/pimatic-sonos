[![npm version](https://badge.fury.io/js/pimatic-sonos.svg)](http://badge.fury.io/js/pimatic-sonos)

pimatic-sonos
===========

##Important
This plugin is still under development, please remain calm.. :sunglasses:

pimatic plugin for controlling the [Sonos Music Player](http://www.sonos.com/).

###device config example:

```json
{
  "id": "sonos-player",
  "name": "Living room",
  "class": "SonosPlayer",
  "host": "192.168.1.102",
  "port": 1400
}
```

###device rules examples:

<b>Play music</b><br>
if smartphone is present then play sonos-player

<b>Pause music</b><br>
if smartphone is absent then pause sonos-player

<b>Change volume</b><br>
if buttonVolumeLow is pressed then change volume of sonos-player to 5

<b>Next song</b><br>
if buttonNext is pressed then play next song Music

<b>Previous song</b><br>
if buttonPrev is pressed then play previous song Music

Currently no predicates for the sonos plugin. If you would like to do something when the state changes u could use the attribute predicate.<br>
if $sonos-player.state equals \"play\" then switch speakers on <br>
if $sonos-player.state equals \"pause\" then switch speakers off <br>
if $sonos-player.currentArtist equals \"rick astley\" then switch speakers off <br>
if $sonos-player.currentTitle equals \"coco jambo\" then change volume of sonos-player to 20 <br>

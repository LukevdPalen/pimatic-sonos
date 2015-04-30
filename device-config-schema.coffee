module.exports ={
  title: "pimatic-sonos device config schemas"
  SonosPlayer: {
    title: "Sonos config options"
    type: "object"
    extensions: ["xLink"]
    properties:
      port:
        description: "The port of sonos player"
        type: "number",
        default: 1400
      host:
        description: "The address of sonos player"
        type: "string"
  }
}
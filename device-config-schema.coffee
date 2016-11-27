module.exports ={
  title: "pimatic-buienradar device config schemas"
  BuienradarDevice: {
    title: "BuienradarDevice"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      latitude:
        description: "Latitude (53.22)"
        type: "string"
        required: true
      longitude:
        description: "Longitude (6.57)"
        type: "string"
        required: true
      minutes:
        description: "Minutes in the future (up to 115 minutes, 0 = now)"
        type: "integer"
        default: 0
  }
}

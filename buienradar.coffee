module.exports = (env) ->
  rp = require 'request-promise'

  class Buienradar extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("BuienradarDevice", {
        configDef: deviceConfigDef.BuienradarDevice,
        createCallback: (config) => new BuienradarDevice(config)
      })

  class BuienradarDevice extends env.devices.Device
    attributes:
      rain:
        description: "The expected rain in mm/hour"
        type: "number"
        unit: 'mm/hour'
        acronym: 'RAIN'

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @minutes = Math.ceil(@config.minutes / 5) * 5 # Round to nearest five minutes
      @latitude = @_round(@config.latitude, 2)
      @longitude = @_round(@config.longitude, 2)
      @url = "http://gpsgadget.buienradar.nl/data/raintext/?lat=#{@latitude}&lon=#{@longitude}"
      @timeout = 60000 # Check for changes every minute

      super()
      @requestData()

    destroy: () ->
      @requestPromise.cancel() if @requestPromise?
      clearTimeout @requestTimeout if @requestTimeout?
      super

    requestData: () =>
      @requestPromise = rp(@url)
        .then((data) =>
          startTime = @_getStartTime(data);
          forecastTime = @_formatTime(@_timeWithOffset(startTime.hours, startTime.minutes, @minutes));
          rain = @_getRainAmountForTime(data, forecastTime)

          # Convert to mm/hour
          rain = @_round(Math.pow(10, (rain - 109) / 32), 1)

          env.logger.debug("Rain amount: #{rain}")

          @_setAttribute "rain", rain

          @_currentRequest = Promise.resolve()
        )
        .catch((err) =>
          env.logger.error(err.message)
          env.logger.debug(err.stack)
        )

      @_currentRequest = @requestPromise unless @_currentRequest?
      @requestTimeout = setTimeout(@requestData, @timeout)
      return @requestPromise

    _setAttribute: (attributeName, value, discrete = false) ->
      if not discrete or @[attributeName] isnt value
        @[attributeName] = value
        @emit attributeName, value

    _timeWithOffset: (hours, minutes, offsetMinutes) ->
      t = new Date()
      t.setHours(hours)
      t.setMinutes(minutes)
      t.setSeconds(t.getSeconds() + offsetMinutes * 60)
      return t

    _formatTime: (time) ->
      # pad time with zeros if necessary
      return ("0" + time.getHours()).slice(-2) + ':' +
        ("0" + time.getMinutes()).slice(-2)

    _getRainAmountForTime: (data, time) ->
      rows = data.split("\n")

      for row in rows
        matches = row.match(/(\d+)\|(\d{2}:\d{2})/m)

        if matches == null
          continue

        matchedRain = matches[1] # 0-255
        matchedTime = matches[2]

        if time == matchedTime
          return parseInt(matchedRain)

    _getStartTime: (data) ->
      firstRow = data.split("\n")[0]
      matches = firstRow.match(/\d+\|(\d{2}):(\d{2})/m)

      return {
        hours: matches[1],
        minutes: matches[2],
      }

    _round: (number, precision) ->
      factor = Math.pow(10, precision)
      tempNumber = number * factor
      roundedTempNumber = Math.round(tempNumber)
      roundedTempNumber / factor

    getRain: ->
      @_currentRequest.then(=> @rain)

  plugin = new Buienradar
  return plugin

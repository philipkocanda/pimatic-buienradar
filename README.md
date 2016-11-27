pimatic-buienradar
===================

Pimatic plugin that retrieves the local precipitation forecast for **the Netherlands**.

No API key required, uses: http://gpsgadget.buienradar.nl/data/raintext/?lat=53.22&lon=6.57

Configuration
-------------

### Plugin Configuration

Add the plugin to the plugin section:

    {
      "plugin": "buienradar",
      "debug": false
    }

### Device Configuration

Then add the device with the location into the devices section:

    {
      "id": "buienradar-groningen",
      "class": "BuienradarDevice",
      "name": "Rain in Groningen (60 minute forecast)",
      "latitude": "53.2193840",
      "longitude": "6.5665020",
      "minutes": 60,
    }
    
The maximum forecast is 115 minutes and is returned in mm/hour precipitation.


### Usage

This makes the variable `$buienradar-groningen.rain` available to you in Pimatic.

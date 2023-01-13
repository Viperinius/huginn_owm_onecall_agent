module Agents
  class OwmOnecallAgent < Agent
    cannot_receive_events!
    can_dry_run!
    default_schedule 'never'

    description <<-MD
      The OWM OneCall Agent queries the OneCall API of [OpenWeatherMap](https://openweathermap.org/) for a given location by `latitude` and `longitude`.
      
      This API returns information about:
      * Current weather
      * Minutely forecast
      * Hourly forecast
      * Daily forecast
      * National weather alerts
      
      Options:
      * `api_key` - Your API key for OpenWeatherMap
      * `latitude` - Part of the geographical coordinates of the targeted location
      * `longitude` - Part of the geographical coordinates of the targeted location
      * `units` - Measurement units (default is `standard`, other possible values are: `metric`, `imperial`)
      * `language` - Return some fields in this language
    MD
    
    event_description <<-MD
      Events look like this:
        {
          "lat": 33.44,
          "lon": -94.04,
          "timezone": "America/Chicago",
          "timezone_offset": -21600,
          "current": {
            "dt": 1673633298,
            "sunrise": 1673616025,
            "sunset": 1673652524,
            "temp": 9.89,
            "feels_like": 7.66,
            "pressure": 1028,
            "humidity": 40,
            "dew_point": -2.71,
            "uvi": 2.98,
            "clouds": 0,
            "visibility": 10000,
            "wind_speed": 4.47,
            "wind_deg": 303,
            "wind_gust": 7.15,
            "weather": [
              {
                "id": 800,
                "main": "Clear",
                "description": "clear sky",
                "icon": "01d"
              }
            ]
          },
          "minutely": [
            {
              "dt": 1673633340,
              "precipitation": 0
            },
            ...
          ],
          "hourly": [
            {
              "dt": 1673632800,
              "temp": 9.89,
              "feels_like": 8.07,
              "pressure": 1028,
              "humidity": 40,
              "dew_point": -2.71,
              "uvi": 2.98,
              "clouds": 0,
              "visibility": 10000,
              "wind_speed": 3.58,
              "wind_deg": 326,
              "wind_gust": 5.03,
              "weather": [
                {
                  "id": 800,
                  "main": "Clear",
                  "description": "clear sky",
                  "icon": "01d"
                }
              ],
              "pop": 0
            },
            ...
          ],
          "daily": [
            {
              "dt": 1673632800,
              "sunrise": 1673616025,
              "sunset": 1673652524,
              "moonrise": 1673675220,
              "moonset": 1673630040,
              "moon_phase": 0.71,
              "temp": {
                "day": 9.89,
                "min": 0.26,
                "max": 10.39,
                "night": 2.15,
                "eve": 5.89,
                "morn": 0.6
              },
              "feels_like": {
                "day": 8.07,
                "night": -0.01,
                "eve": 3.46,
                "morn": -3.21
              },
              "pressure": 1028,
              "humidity": 40,
              "dew_point": -2.71,
              "wind_speed": 4.25,
              "wind_deg": 327,
              "wind_gust": 9.97,
              "weather": [
                {
                  "id": 800,
                  "main": "Clear",
                  "description": "clear sky",
                  "icon": "01d"
                }
              ],
              "clouds": 0,
              "pop": 0,
              "uvi": 2.98
            },
            ...
          ],
          "alerts": [
            {
              "sender_name": "Example name",
              "event": "wind gusts",
              "start": 1673564400,
              "end": 1673636400,
              "description": "Example example example",
              "tags": [
                "Wind",
                "Wind"
              ]
            }
          ]
      }
      
      Some keys like `alerts` might be missing if they are not applicable for the given location at this time.
    MD

    def default_options
      {
        'api_key' => '',
        'latitude' => '',
        'longitude' => '',
        'units' => 'metric',
        'language' => 'en',

        'emit_events' => 'false',
        'expected_receive_period_in_days' => '1'
      }
    end

    def validate_options
    end

    def working?
      event_created_within?((interpolated['expected_receive_period_in_days'].presence || 10).to_i) && !recent_error_logs?
    end

#    def check
#    end

#    def receive(incoming_events)
#    end
  end
end

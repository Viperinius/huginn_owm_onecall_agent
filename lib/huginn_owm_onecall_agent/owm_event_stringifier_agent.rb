module Agents
  class OwmEventStringifierAgent < Agent
    include FormConfigurable

    can_dry_run!
    cannot_be_scheduled!

    description <<-MD
      The OWM Event Stringifier Agent converts the results of the OWM OneCall Agent to categorised string representations.

      Options:
      
      * `Mode` - Decide whether to merge the results with the original event
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

    form_configurable :mode, type: :array, values: %w[Merge Clean]

    def default_options
      {
        'mode' => 'Merge'
      }
    end

    def validate_options
      errors.add(:base, "mode is required") unless options['mode'].present?
      errors.add(:base, "mode must be valid value") unless %w(Merge Clean).include?(interpolated['mode'])
    end

    def working?
      !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          stringified = stringify_meta(event)
          stringified.merge! stringify_current(event)
          stringified.merge! stringify_minutely(event)
          stringified.merge! stringify_hourly(event)
          stringified.merge! stringify_daily(event)
          stringified.merge! stringify_alerts(event)

          formatted_event = interpolated['mode'] == 'Merge' ? event.payload.dup : {}
          formatted_event.merge! stringified

          create_event :payload => formatted_event
        end
      end
    end

    GROUP_SUN = 'sun_moon'
    GROUP_TEMPERATURE = 'temperature'
    GROUP_PRECIPITATION = 'precipitation'
    GROUP_WIND = 'wind'
    GROUP_WEATHER = 'weather'
    GROUP_OTHER = 'other'
    
    def stringify_meta(event)
      meta = []

      %w[lat lon timezone timezone_offset].each do |key|
        meta.push("#{key}=#{event.payload[key]}") if event.payload[key].present?
      end

      { 'str_meta': meta.join(',') }
    end

    def stringify_alerts(event)
      alerts = []

      if event.payload['alerts'].present?
        event.payload['alerts'].each do |alert|
          alert_items = []
          %w[sender_name start end].each do |key|
            alert_items.push("#{key}=#{alert[key]}") if alert[key].present?
          end
          %w[event description].each do |key|
            alert_items.push("#{key}=\"#{alert[key]}\"") if alert[key].present?
          end

          # TODO: include tags as well?

          alerts.push(alert_items.join(','))
        end
      end

      { 'str_alerts': alerts }
    end

    def stringify_minutely(event)
      minutely = []

      if event.payload['minutely'].present?
        event.payload['minutely'].each do |point|
          point_entries = []
          %w[dt precipitation].each do |key|
            point_entries.push("#{key}=#{point[key]}") if point[key].present?
          end

          minutely.push({ "#{GROUP_PRECIPITATION}": point_entries.join(',') })
        end
      end

      { 'str_minutely': minutely }
    end

    def stringify_current(event)
      { 'str_current': stringify_default(event.payload['current']) }
    end

    def stringify_hourly(event)
      { 'str_hourly': stringify_default(event.payload['hourly']) }
    end

    def stringify_daily(event)
      { 'str_daily': stringify_default(event.payload['daily']) }
    end

    # ###################################
    def stringify_default(data)
      groups = {}

      sun_items = []
      %w[sunrise sunset moonrise moonset moon_phase].each do |key|
        sun_items.push("#{key}=#{data[key]}") if data[key].present?
      end
      groups["#{GROUP_SUN}"] = sun_items.join(',')

      temp_items = []
      %w[temp feels_like dew_point].each do |key|
        if data[key].present?
          if data[key].kind_of? Hash
            temp_items.push("#{key}=#{data[key]}")
          else
            %w[morn day eve night min max].each do |inner_key|
              temp_items.push("#{key}_#{inner_key}=#{data[key][inner_key]}") if data[key][inner_key].present?
            end
          end
        end
      end
      groups["#{GROUP_TEMPERATURE}"] = temp_items.join(',')

      precip_items = []
      %w[rain snow pop].each do |key|
        if data[key].present?
          if data[key].kind_of? Hash && data[key]['1h'].present?
            precip_items.push("#{key}=#{data[key]['1h']}")
          else
            precip_items.push("#{key}=#{data[key]}")
          end
        else
          precip_items.push("#{key}=0") 
        end
      end
      groups["#{GROUP_PRECIPITATION}"] = precip_items.join(',')

      wind_items = []
      %w[wind_speed wind_deg wind_gust].each do |key|
        wind_items.push("#{key}=#{data[key]}") if data[key].present?
      end
      groups["#{GROUP_WIND}"] = wind_items.join(',')

      weather_items = []
      if data['weather'].present? && data['weather'].length > 0
        %w[id main description icon].each do |key|
          weather_items.push("#{key}=#{data['weather'][0][key]}") if data['weather'][0][key].present?
        end
      end
      groups["#{GROUP_WEATHER}"] = weather_items.join(',')

      other_items = []
      %w[pressure humidity clouds visibility uvi].each do |key|
        other_items.push("#{key}=#{data[key]}") if data[key].present?
      end
      groups["#{GROUP_OTHER}"] = other_items.join(',')

      groups
    end

  end
end

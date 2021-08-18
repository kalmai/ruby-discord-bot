require 'dotenv'
require 'discordrb'
require 'pry'
require 'net/http'
require 'json'

Dotenv.load('.env')

bot = Discordrb::Bot.new token: ENV['TOKEN']

def wind_direction_finder(degrees)
  hsh = {
    "north" => (0 - degrees).abs,
    "east" => (90 - degrees).abs,
    "south" => (180 - degrees).abs,
    "west" => (270 - degrees).abs,
    "north_east" => (45 - degrees).abs,
    "north_west" => (135 - degrees).abs,
    "south_east" => (225 - degrees).abs,
    "south_west" => (315 - degrees).abs,
  }

  return hsh.min_by{ |k, v| v}[0]

end

def return_weather_for_city(city)
  uri = URI("http://api.openweathermap.org/data/2.5/find?q=#{city}&units=metric&type=accurate&mode=yml&APPID=#{ENV['KEY']}")
  res = Net::HTTP.get_response(uri)
  JSON.parse(res.body)
end

def return_cloudiness_string(percentage)
  if percentage >= 75
    return "cloudy"
  elsif percentage < 75 && percentage >= 50
    return "mostly cloudy"
  elsif percentage < 50 && percentage >= 25
    return "slightly cloudy"
  else
    return "clear"
  end
end

def weather_string_builder(weather)
  current_weather = weather['weather'].first['description']
  temp = weather['main']['temp']
  feels_like = weather['main']['feels_like']
  humidity = weather['main']['humidity']
  wind = weather['wind']
  wind_speed = wind['speed']
  wind_direction = wind_direction_finder(wind['deg'])
  rain = " with #{weather['rain']['1h']} mm of rain in the last hour" unless weather['rain'].nil?
  snow = " with #{weather['snow']['1h']} mm of snow in the last hour" unless weather['snow'].nil?
  cloudy = return_cloudiness_string(weather['clouds'].values[0])
  weather_string = "#{current_weather.capitalize} at #{temp}°C with a humidity of #{humidity}% and it feels like #{feels_like}°C, #{cloudy} with a wind direction of #{wind_direction} and a speed of #{wind_speed}m/s"
  weather_string << rain if rain
  weather_string << snow if snow

  return weather_string
end

def process_coords_to_address(locations)
  if locations.size > 0
    uri_string = "http://www.mapquestapi.com/geocoding/v1/batch?key=#{ENV['MAP_KEY']}"
    locations.each do |id, coords| 
      coord_string = coords[0].to_s << ',' << coords[1].to_s
      uri_string = uri_string << "&location=#{coord_string}"
    end
    uri = URI(uri_string)

    res = Net::HTTP.get_response(uri)
    json = JSON.parse(res.body)
    json['results'].each do |city|
      aa1 = city['locations'][0]['adminArea1']
      aa3 = city['locations'][0]['adminArea3']
      aa4 = city['locations'][0]['adminArea4']
      aa5 = city['locations'][0]['adminArea5']
      aa6 = city['locations'][0]['adminArea6']
      reverse_geocoord_locations = "#{aa1} #{aa3} #{aa4} #{aa5} #{aa6}"
      matching_coords_city = locations.select { |k, v| v == city['providedLocation']['latLng'].values }

      locations[matching_coords_city.keys.first] = reverse_geocoord_locations
      
    end
    return locations

  end

end

bot.message() do |event|
  event.message.delete

  user_input = event.message.content.split(' ')
  if user_input.shift.eql?('!weather')
    city = user_input.join(' ')

    data = return_weather_for_city(city)
    unless data['list'].empty?

      locations = data['list'].each.with_object({}) do |location, hsh|
        id = location['id']
        coords = location['coord'].values
        unless hsh.values.include?(coords)
          hsh[id] = coords
        end
      end

      response = process_coords_to_address(locations)
      if response.size > 1
        id_select = response.dup
        reply = "Enter the corresponding number to the location you want to know the weather for:\n"
        i = 1
        id_select.each do |k, v|
          reply << "#{i}. #{v}\n"
          id_select[k] = i
          i += 1
        end
        event.user.dm(reply)
        event.user.await(:selection) do |reply_event|
          selection = id_select.select { |k, v| v == reply_event.message.content.to_i }.keys.first
          weather = data['list'].select { |d| d['id'] == selection } 
          weather_string = weather_string_builder(weather.first)

          reply_event.user.dm("The weather in #{response[selection]} is: " << weather_string)
        end
      elsif response.size == 1
        weather_string = weather_string_builder(data['list'][0])
        event.user.dm("The weather in #{response.values.first} is: " << weather_string)
      end
    else
      event.user.dm("Please enter a valid location e.g. 'New York'")
    end
  else
    event.user.dm("Please enter a valid command e.g. '!weather New York'")
  end
end


bot.run

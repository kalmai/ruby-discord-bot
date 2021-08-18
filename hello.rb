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
  uri = URI("http://api.openweathermap.org/data/2.5/find?q=#{city}&units=metric&type=accurate&mode=yml&APPID=#{ENV['KEY'].to_s}")
  res = Net::HTTP.get_response(uri)
  JSON.parse(res.body)
end

def weather_string_builder(weather)

    temp = weather['main']['temp']
    humidity = weather['main']['humidity']
    wind = weather['wind']
    wind_speed = wind['speed']
    wind_direction = wind_direction_finder(wind['deg'])
    rain = weather['rain']
    cloudy = weather['clouds'].values[0]
  binding.pry
end

#def remove_duplicates_in_hash(hsh)
#  new_hsh = {}
#
#  hsh.each do |id, coords|
#    unless new_hsh.values.include?(coords)
#      new_hsh[id] = coords
#    end
#  end
#
#  new_hsh
#end

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
  user_input = event.message.content.split(' ')
  if user_input.first.eql?('!weather')
    city = user_input.last

    data = return_weather_for_city(city)
    #data['list'].each { |city| exact_city = city if city['name'].downcase.eql?(event.message.to_s.downcase) }

    locations = data['list'].each.with_object({}) do |location, hsh|
      id = location['id']
      coords = location['coord'].values
      unless hsh.values.include?(coords)
        hsh[id] = coords
      end
    end

    response = process_coords_to_address(locations)
    if response.size > 1
      reply = "Enter the corresponding number to the location you want to know the weather for:\n"
      i = 1
      response.each do |k, v|
        reply << "#{i}. #{v}\n"
        response[k] = i
        i += 1
      end
      event.user.dm(reply)
      event.user.await(:selection) do |reply_event|
        binding.pry
        selection = response.select { |k, v| v == reply_event.message.content.to_i }
        weather = data['list'].select { |d| d['id'] == selection } 
        weather_string = weather_string_builder(weather)

        reply_event.user.dm(weather_string)
      end
    elsif response.size == 1
      weather_string = weather_string_builder(data['list'][0])
      event.user.dm(weather_string)
    end

    #event.user.dm(response.to_s)
    #event.user.await(:empty) do |reply_event|
    #  reply_event.user.dm(reply_event.message.content << 'hey again')
    #end

    #bot.add_await!() do |reply_event|
    #  binding.pry
    #end
    #test = response['results'][0]['locations'][0]
    #test2 = response['results']
    #temp = exact_city['main']['temp']
    #humidity = exact_city['main']['humidity']
    #wind = exact_city['wind']
    #wind_speed = wind['speed']
    #wind_direction = wind_direction_finder(wind['deg'])
    #rain = exact_city['rain']
    #cloudy = exact_city['clouds'].values[0]

    #event.respond "#{locations.to_s}"
    #event.respond "#{event.message} Pong!"
  end
end


bot.run

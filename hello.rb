require 'dotenv'
require 'discordrb'
require 'pry'
require 'net/http'
require 'json'

Dotenv.load('.env')
#change

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

bot.message() do |event|
  uri = URI("http://api.openweathermap.org/data/2.5/find?q=#{event.message}&units=metric&type=accurate&mode=yml&APPID=#{ENV['KEY'].to_s}")
  res = Net::HTTP.get_response(uri)
  data = JSON.parse(res.body)
  exact_city = nil
  data['list'].each { |city| exact_city = city if city['name'].downcase.eql?(event.message.to_s.downcase) }
  temp = exact_city['main']['temp']
  humidity = exact_city['main']['humidity']
  wind = exact_city['wind']
  wind_speed = wind['speed']
  wind_direction = wind_direction_finder(wind['deg'])
  rain = exact_city['rain']
  cloudy = exact_city['clouds'].values[0]
  binding.pry



  # => {"id"=>1850147,                                                                                                                                                                                                    "name"=>"Tokyo",                                                                                                                                                                                                     "coord"=>{"lat"=>35.6895, "lon"=>139.6917},                                                                                                                                                                          "main"=>{"temp"=>28.03, "feels_like"=>32.33, "temp_min"=>25.44, "temp_max"=>29.24, "pressure"=>1002, "humidity"=>81},                                                                                                "dt"=>1628456952,                                                                                                                                                                                                    "wind"=>{"speed"=>0.89, "deg"=>202},                                                                                                                                                                                 "sys"=>{"country"=>"JP"},                                                                                                                                                                                            "rain"=>nil,                                                                                                                                                                                                         "snow"=>nil,                                                                                                                                                                                                         "clouds"=>{"all"=>75},                                                                                                                                                                                               "weather"=>[{"id"=>803, "main"=>"Clouds", "description"=>"broken clouds", "icon"=>"04d"}]}  

  #res = Net::HTTP.start(uri.host, uri.port) {|http|
  #  request = Net::HTTP::Get.new uri
  #  response = http.request request
  #  puts response
  #}
  #puts res.body
  event.respond "#{event.message} Pong!"
end

bot.run

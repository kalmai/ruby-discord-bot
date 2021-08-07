require 'dotenv'
require 'discordrb'
require 'pry'

Dotenv.load('.env')
#change

bot = Discordrb::Bot.new token: ENV['TOKEN']

bot.message() do |event|
  event.respond "#{event.message} Pong!"
end

bot.run

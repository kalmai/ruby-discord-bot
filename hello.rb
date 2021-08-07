require 'dotenv'
require 'discordrb'
require 'pry'

Dotenv.load('.config.env')

bot = Discordrb::Bot.new token: ENV['TOKEN']

bot.message() do |event|
  event.respond 'Pong!'
end

bot.run

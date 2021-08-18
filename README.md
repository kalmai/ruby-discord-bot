This bot uses free apis to get weather and reverse geocode the locations returned from the weather api to private message the user the current weather for the location they've selected.
To run this application, install the following and set up your '.env' like so...

* Installation
```
$ git clone https://github.com/kalmai/ruby-discord-bot.git
$ cd ruby-discord-bot
$ gem install discordrb
$ gem install dotenv
```

* '.env' file
```
TOKEN=<this is where your discord bot token goes>
KEY=<this is where your openweathermap.org api key goes>
MAP_KEY=<this is where your mapquest.com api key goes>
```
You must sign up for [openweathermap.org](https://home.openweathermap.org/users/sign_up) and [mapquest.com](https://developer.mapquest.com/plan_purchase/steps/business_edition/business_edition_free/register) apis in order to run this application. Additionally, you can follow [this post](https://medium.com/@goodatsports/how-to-make-a-simple-discord-bot-in-ruby-to-annoy-your-friends-f5d0438daa70) to create your bot in order to get the required token.

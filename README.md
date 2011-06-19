## About me ##

AutoMan is a test automation solution developed by TaoBao UI Automation Team.
AutoMan includes test framework in client side and PageModel web service in
server side.
Automan-server is a http service build on rails to help user setup the page 
model. After page model ready, client side will download the page model from 
server side, then load and use them in test scripts.

## About demo site ##
Our [demo site](http://automan.heroku.com)

## How to install ##

1. git clone git@github.com:automan/automan-server.git
2. cd automan-server 
3. cp config/database.yml.example.yml config/database.yml
4. rake db:create:all
5. rake db:migrate

## Config you own server ##

After installation, you should config automan-server by editing config/tam_config.rb

change

	ActiveRecord::Base.default_url_options = {:host => "automan.heroku.com"}

to

	ActiveRecord::Base.default_url_options = {:host => "you server host or ip address"}


All finished, have fun!


## FAQ ##

#### How to Run with automan-client ####

	update config/automan_config.rb in client machine

config.tam_host           = "use your server here"

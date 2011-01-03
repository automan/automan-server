## About me ##

automan is a .....,  automan-server is a....

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

	TODO

TODO
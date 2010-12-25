require "digest/sha1"
class User < ActiveRecord::Base
  include Automan::UserExt
  has_many :ownerables, :dependent => :delete_all
  has_many :user_favs, :dependent => :delete_all
  
  def name
  	nickname
  end
  
  def to_s
    login
  end
  
  def logged?
    true
  end
  
  def anonymous?
    !logged?
  end
        
  def self.current=(user)
    @current_user = user
  end
  
  def self.current
    @current_user ||= User.first#("admin")
  end

end
# frozen_string_literal: true

require 'trello'
require 'logger'
require 'singleton'

# A Trello user.
class TrelloUser
  include Singleton
  attr_accessor :user, :logger

  def initialize
    configure_trello!
    @logger = Logger.new($stdout)
    @logger.level = ENV['LOG_LEVEL'] || Logger::WARN
    @logger.debug("Searching for Trello ID #{ENV['TRELLO_USER_ID']}; please standby")
    @user = Trello::Member.find(ENV['TRELLO_USER_ID'])

    raise "No user found matching #{@user} with supplied credentials" if @user.nil?
  end

  def configure_trello!
    Trello.logger = Logger.new('/dev/null')
    Trello.configure do |conf|
      conf.developer_public_key = ENV['TRELLO_PUBLIC_KEY']
      conf.member_token = ENV['TRELLO_MEMBER_TOKEN']
    end
  end

  def filter_boards(names)
    @logger.debug "Searching for boards matching #{names}"
    @user.boards.select do |board|
      names.include?(board.name)
    end
  end

  def with_retries(&block)
    attempts = 0
    raise 'Max attempts exceeded' unless attempts != 5

    loop do
      return block.call
    rescue Trello::Error => e
      wait = sleep rand(5..7)
      @logger.debug("Sleeping #{wait} seconds due to Trello API error: #{e}, call: #{block.to_source}")
      sleep wait
      attempts += 1
      retry
    end
  end
end

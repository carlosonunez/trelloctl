# frozen_string_literal: true

require 'json'
require 'thread/pool'
require 'trello'
require 'trelloctl'
require 'yaml'

PROGRAM_BANNER = "#{$PROGRAM_NAME}: Lists labels associated with one or more boards"

options = Options.new(PROGRAM_BANNER)
options.add_option(long_flag: '--boards',
                   description: 'The boards from which the label should be removed',
                   type: Array,
                   id: 'boards',
                   required: true)
options.add_option(long_flag: '--output',
                   description: 'Output format',
                   id: 'format',
                   default: 'yaml',
                   acceptable: %w[yaml json])
options.gather!(ARGV)
options.exit_if_usage_set!
options.exit_if_missing_required_vars!

boards = options.value(:boards)
user = TrelloUser.instance

boards_pool = Thread.pool(5)
labels = []
user.filter_boards(boards).each do |board_ref|
  boards_pool.process do
    user.with_retries { Trello::Board.find(board_ref.id) }.labels.map do |label|
      labels << {
        label: {
          name: label.name,
          id: label.id,
          board: {
            name: board_ref.name,
            id: board_ref.id
          }
        }
      }
    end
  end
end
boards_pool.shutdown
json = labels.to_json
if options.value(:format) == 'yaml'
  puts YAML.safe_load(json).to_yaml
else
  puts json
end

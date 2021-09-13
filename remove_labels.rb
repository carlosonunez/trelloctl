# frozen_string_literal: true

require 'thread/pool'
require 'trello'
require 'trelloctl'

PROGRAM_BANNER = "#{$PROGRAM_NAME}: Removes labels from a board. Does not remove cards \
to which the label is associated."

options = Options.new(PROGRAM_BANNER)
options.add_option(long_flag: '--boards',
                   description: 'The boards from which the label should be removed',
                   type: Array,
                   id: 'boards')
options.add_option(long_flag: '--labels',
                   description: 'The labels to remove',
                   type: Array,
                   id: 'labels')
options.add_option(short_flag: '-f',
                   long_flag: '--labels-file',
                   description: 'A file containing labels to remove.',
                   id: 'labels_file')
options.add_option(long_flag: '--dry-run',
                   description: 'Show what labels will be deleted instead of deleting them',
                   type: TrueClass,
                   id: 'dry_run',
                   default: false)
options.gather!(ARGV)
options.exit_if_usage_set!
options.exit_if_missing_required_vars!

raise 'Either --labels or --labels-file must be specified' \
  unless options.has?(:labels) || options.has?(:labels_file)

boards = options.value(:boards)
labels = if options.has?(:labels_file)
           File.read(options.value(:labels_file))
         else
           options.value(:labels)
         end

user = TrelloUser.instance

boards_pool = Thread.pool(5)
labels_to_delete = []
user.filter_boards(boards).each do |board_ref|
  boards_pool.process do
    labels_to_delete +=
      user.with_retries { Trello::Board.find(board_ref.id) }.labels.select do |label|
        labels.include?(label.name) || labels.include?(label.id)
      end.map do |label|
        JSON.parse({
          name: label.name,
          id: label.id,
          board: {
            name: board_ref.name,
            id: board_ref.id
          }
        }.to_json, object_class: OpenStruct)
      end
  end
end
boards_pool.shutdown
labels_pool = Thread.pool(10)
labels_to_delete.each do |label|
  labels_pool.process do
    if options.value(:dry_run) == true
      puts "---> Deleting [#{label.name}] from board [#{label.board.name}] (dry run)"
    else
      puts "---> Deleting [#{label.name}] from board [#{label.board.name}]"
      Trello::Label.find(label.id).delete
    end
  end
end
labels_pool.shutdown

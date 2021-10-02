# frozen_string_literal: true

# delete_cards: Delete cards matching criteria

require 'trello'
require 'logger'
require 'singleton'
require 'thread/pool'
require 'trelloctl'

TRIGGER_PHRASE_LITERAL = '┆Card is synchronized with this'
TRIGGER_PHRASE_REGEXP = /┆Card is synchro.*by \[Unito\].*$/
PROGRAM_BANNER = "#{$PROGRAM_NAME}: Removes the Unito comment from card descriptions"

def collect_target_cards_from_boards(user, boards, _lists = [])
  board_pool = Thread.pool(5)
  list_pool = Thread.pool(10)
  card_pool = Thread.pool(25)
  cards = []
  user.filter_boards(boards).each do |board_ref|
    board_pool.process do
      user.with_retries { Trello::Board.find(board_ref.id) }.lists.each do |list_ref|
        list_pool.process do
          user.with_retries { Trello::List.find(list_ref.id) }.cards.each do |card_ref|
            card_pool.process do
              card = user.with_retries { Trello::Card.find(card_ref.id) }
              user.logger.debug("Inspecting card '#{card.name}' in board #{board_ref.name}...")
              cards << card_ref.id if card.desc.include?(TRIGGER_PHRASE_LITERAL)
            end
          end
        end
      end
    end
  end
  board_pool.shutdown
  list_pool.shutdown
  card_pool.shutdown
  cards
end

def update_descriptions(user, card_refs)
  pool = Thread.pool(50)
  card_refs.each do |ref|
    pool.process do
      card = user.with_retries { Trello::Card.find(ref) }
      new_desc = card.desc.gsub(TRIGGER_PHRASE_REGEXP, '').strip
      user.with_retries do
        card.desc = new_desc
        card.save
      end
      puts "   ---> Card updated: '#{card.name}'"
    end
  end
  pool.shutdown
end

ARGV << '-h' if ARGV.empty?
options = Options.new(PROGRAM_BANNER)
options.add_option(long_flag: '--boards',
                   description: 'The boards from which cards will be modified',
                   type: Array,
                   id: :boards,
                   required: true)
options.add_option(long_flag: '--list',
                   type: Array,
                   description: 'The list from which cards should be deleted',
                   id: :list)
options.add_option(long_flag: '--dry-run',
                   description: 'Do not delete; perform dry run instead',
                   id: :dry_run)
options.gather!(ARGV)
options.exit_if_usage_set!
options.exit_if_missing_required_vars!

boards = options.value(:boards)
lists = options.value(:list) || []
raise '--boards cannot be empty' if boards.nil? || boards.empty?

puts "---> Collecting cards from #{boards}. This might take a few minutes."
target_cards = collect_target_cards_from_boards(TrelloUser.instance, boards, lists)
puts "---> Removing /#{TRIGGER_PHRASE_REGEXP}/ from #{target_cards.length} cards. This might also take a few minutes."
delete_cards(target_cards, dry_run)

# frozen_string_literal: true

require 'optparse'

class OptionParsing
  def self.gather_options(args)
    options = {}
    OptionParser.new do |opts|
      opts.banner = <<~BANNER
        #{$PROGRAM_NAME} --boards BOARD_1 BOARD_2...
        Removes the description left behind by the Unito app thing.
      BANNER
      opts.on('', '--boards board_1, board_2, ...', Array, 'The names of the boards to modify') do |v|
        options[:boards] = v
      end
      opts.on('-h', '--help', 'Show this help text') do
        options[:usage] = opts.help
      end
    end.parse!(args)
    options
  end
end

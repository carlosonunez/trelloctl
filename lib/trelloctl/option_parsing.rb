# frozen_string_literal: true

require 'optparse'
require 'ostruct'

class OptionConfig
  attr_reader :options, :banner, :flag_example

  def initialize(banner)
    @banner = banner
    @options = {}
  end

  def add_option(long_flag:, description:, id:, type: String, short_flag: '')
    long_flag_full = case type.to_s
                     when Array.to_s
                       "#{long_flag} ITEM_1, ITEM_2"
                     when String.to_s
                       long_flag.to_s + 'ITEM'
                     when Integer.to_s
                       long_flag.to_s + 42.to_s
                     else
                       long_flag
                     end
    @options[id.to_sym] = OpenStruct.new({ long_flag: long_flag_full,
                                           short_flag: short_flag,
                                           description: description,
                                           type: type })
  end
end

class OptionParsing
  def self.gather_options(args:, config:)
    raise 'Please create an option config' if config.options.empty?

    options = {}
    OptionParser.new do |opts|
      opts.banner = config.banner
      config.options.each do |id, opt|
        opts.on(opt.short_flag, opt.long_flag, opt.type, opt.description) do |v|
          options[id.to_sym] = v
        end
      end
      opts.on('-h', '--help', 'Show this help text') do
        options[:usage] = opts.help
      end
    end.parse!(args)
    options
  end
end

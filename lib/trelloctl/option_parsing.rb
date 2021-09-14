# frozen_string_literal: true

require 'optparse'
require 'ostruct'

class Options
  attr_reader :options, :banner, :flag_example, :rendered

  def initialize(banner)
    @banner = banner
    @options = {}
    @rendered = {
      show_usage: false
    }
  end

  def has?(id)
    @rendered.key?(id)
  end

  def value(id)
    @rendered[id]
  end

  def gather!(args)
    args << '-h' if args.empty?
    OptionParser.new do |opts|
      opts.banner = @banner
      @options.each do |id, opt|
        if opt.acceptable.empty?
          opts.on(opt.short_flag, opt.long_flag, opt.type, opt.description) do |v|
            @rendered[id.to_sym] = v
          end
        else
          opts.on(opt.short_flag, opt.long_flag, opt.type, opt.description, opt.acceptable) do |v|
            @rendered[id.to_sym] = v
          end
        end
      end
      opts.on('-h', '--help', 'Show this help text') do
        @rendered[:show_usage] = true
      end
      @rendered[:usage_text] = opts.help
    end.parse!(args)
  end

  def exit_if_usage_set!
    raise 'Please `gather!` options first' if @rendered.empty?

    return unless @rendered[:show_usage]

    puts @rendered[:usage_text]
    exit
  end

  def exit_if_missing_required_vars!
    raise 'Please `gather!` options first' if @rendered.empty?

    @missing = @options.keys.select do |opt|
      @options[opt][:required] && !@rendered.key?(opt)
    end.map do |opt|
      @options[opt][:long_flag].split(' ').first
    end
    return if @missing.empty?

    puts @rendered[:usage_text]
    raise "Please define: #{@missing}"
  end

  def add_option(long_flag:,
                 description:,
                 id:,
                 type: String,
                 short_flag: '',
                 required: false,
                 default: nil,
                 acceptable: [])
    long_flag_full = case type.to_s
                     when Array.to_s
                       "#{long_flag} ITEM_1, ITEM_2"
                     when String.to_s
                       "#{long_flag} ITEM"
                     when Integer.to_s
                       long_flag.to_s + 42.to_s
                     else
                       long_flag
                     end
    @rendered[:id] = default unless default.nil?
    description = "#{description} (Acceptable values: #{acceptable})" unless acceptable.empty?
    @options[id.to_sym] = OpenStruct.new({ long_flag: long_flag_full,
                                           short_flag: short_flag,
                                           description: description,
                                           type: type,
                                           required: required,
                                           acceptable: acceptable })
  end
end

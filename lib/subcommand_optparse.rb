require "subcommand_optparse/version"
require "optparse"
require "active_support/core_ext/array/extract_options"

class SubCmdOptParser
  class OptionParserForSubCmd < OptionParser
    attr_accessor :subcommand_name
    attr_accessor :description

    def initialize(subcmd, description, width, indent)
      @subcommand_name = subcmd
      @description = description
      super(nil, width, indent)
    end

    def banner
      unless @banner
        @banner = "Usage: #{program_name} #{@subcommand_name || '<command>'} [options]"
        if @description
          @banner << "\n\n#{@description}"
        end
        visit(:add_banner, @banner)
      end
      @banner
    end
  end

  attr_accessor :program_name
  attr_accessor :summary_width
  attr_accessor :summary_indent
  alias set_program_name program_name=
  alias set_summary_width summary_width=
  alias set_summary_indent summary_indent=

  # @overload initialize(banner = nil, width = 32, indent = ' ' * 4, opts = {})
  #  @param [String,nil] banner Banne of help
  #  @param [Fixnum] width Width of summary
  #  @param [String] indent Indent of summary
  #  @param [Hash] opts Options hash
  #  @option opts [boolean] :help_command If the value is false then subcommand help is not set automatically
  #  @option opts [boolean] :accept_undefined_command If the value is false then show help for undefined commands
  #  @yield [sc]
  #  @yieldparam [SubCmdOptParser] sc Option parser
  def initialize(*args, &block)
    opts = args.extract_options!
    @banner_help = args.shift
    @summary_width = args[0] || 32
    @summary_indent = args[1] ||  ' ' * 4
    @global_option_setting = nil
    @subcommand = []
    @help_subcommand_use_p = (!opts.has_key?(:help_command) || opts[:help_command])
    @accept_undefined_command = opts[:accept_undefined_command]
    if block_given?
      yield(self)
    end
  end

  # Set options that are available for all subcommands
  # @yield [opt]
  # @yieldparam [OptionParserForSubCmd] opt Option parser for all subcommands
  def global_option(&block)
    @global_option_setting = block
  end

  def subcommand_defined?(subcmd)
    !!@subcommand.assoc(subcmd)
  end

  # @overload subcommand(name, description = nil, opts = {})
  #  @param [String] name Name of subcommand
  #  @param [String] description Description of subcommand whose first line is shows in list of subcommands
  #  @param [Hash] opts Options hash
  #  @option opts [boolean] :load_global_options If the value is false then global options are not loaded
  #  @yield [opt]
  #  @yieldparam [OptionParserForSubCmd] opt Option parser for the subcommand
  def subcommand(name, *args, &block)
    opts = args.extract_options!
    description = args.shift
    if args.size > 0
      raise ArgumentError, "Too many arguments"
    end
    h = { :description => description, :setting => block }
    h[:load_global_options] = !(opts.has_key?(:load_global_options) && !opts[:load_global_options])
    @subcommand << [name, h]
  end

  def get_subcmd_data(subcmd)
    subcmd_data = nil
    if ary = @subcommand.assoc(subcmd)
      subcmd_data = ary[1]
    end
    subcmd_data
  end
  private :get_subcmd_data

  def get_option_parser(subcmd, subcmd_data)
    desc = subcmd_data && subcmd_data[:description]
    opt = OptionParserForSubCmd.new(subcmd, desc, @summary_width, @summary_indent)
    opt.program_name = program_name if @program_name
    subcmd_data[:setting].call(opt) if subcmd_data && subcmd_data[:setting]
    if @global_option_setting && (!subcmd_data || subcmd_data[:load_global_options])
      @global_option_setting.call(opt)
    end
    opt
  end
  private :get_option_parser

  def message_list_subcommands
    mes = "Commands are:\n"
    max_size_subcmd = (@subcommand.map { |name, val| name.size }).max
    str_size = (max_size_subcmd.even? ? max_size_subcmd : max_size_subcmd + 1) + 4
    @subcommand.each do |name, val|
      desc = ((val && val[:description]) ? val[:description].each_line.first.strip : "")
      mes << ("    %-#{str_size}s" % name) << desc << "\n"
    end
    mes
  end
  private :message_list_subcommands

  def get_banner_help(opt)
    if @banner_help
      banner_string = @banner_help
    else
      banner_string = "Usage: #{opt.program_name} <command> [options]"
    end
    banner_string + "\n\n" + message_list_subcommands
  end
  private :get_banner_help

  def parse!(argv = ARGV)
    if @help_subcommand_use_p
      unless subcommand_defined?("help")
        subcommand("help", "Show help message", :load_global_options => false) do |opt|
          opt.banner = get_banner_help(opt)
        end
      end
    end

    subcmd = argv[0]
    if subcmd_data = get_subcmd_data(subcmd)
      argv.shift
    else
      subcmd = nil
      unless @accept_undefined_command
        subcmd = "help"
        subcmd_data = get_subcmd_data(subcmd)
      end
    end
    opt = get_option_parser(subcmd, subcmd_data)
    opt.parse!(argv)

    if @help_subcommand_use_p && subcmd == "help"
      print opt.to_s
      exit
    end

    subcmd
  end
end

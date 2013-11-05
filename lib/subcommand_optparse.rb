require "subcommand_optparse/version"
require "optparse"
require "active_support/core_ext/array/extract_options"

class SubCmdOptParser
  class OptionParserForSubCmd < OptionParser
    attr_accessor :subcommand_name

    def banner
      unless @banner
        @banner = "Usage: #{program_name} #{@subcommand_name || '<command>'} [options]"
        visit(:add_banner, @banner)
      end
      @banner
    end
  end

  # @overload initialize(banner = nil, width = 32, indent = ' ' * 4, opts = {})
  #  @param [String,nil] banner An argument of OptionParser
  #  @param [Fixnum] width An argument of OptionParser
  #  @param [String] indent An argument of OptionParser
  #  @param [Hash] opts Options hash
  #  @option opts [boolean] :help_command If the value is false then subcommand help is not set automatically
  #  @yield [sc]
  #  @yieldparam [SubCmdOptParser] sc Option parser
  def initialize(*args, &block)
    opts = args.extract_options!
    @default_banner = args.shift
    @args_option_parser = args
    @global_option_setting = nil
    @subcommand = []
    @help_subcommand_use_p = (!opts.has_key?(:help_command) || opts[:help_command])
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

  # @overload subcommand(name, banner = nil, opts = {})
  #  @param [String] name Name of subcommand
  #  @param [Hash] opts Options hash
  #  @option opts [boolean] :load_global_options If the value is false then global options are not loaded
  #  @yield [opt]
  #  @yieldparam [OptionParserForSubCmd] opt Option parser for the subcommand
  def subcommand(name, *args, &block)
    opts = args.extract_options!
    banner = args.shift
    h = { :banner => banner, :setting => block }
    h[:load_global_options] = !(opts.has_key?(:load_global_options) && !opts[:load_global_options])
    @subcommand << [name, h]
  end

  def get_banner(subcmd_data)
    (subcmd_data && subcmd_data[:banner]) || @default_banner
  end
  private :get_banner

  def get_subcmd_data(subcmd)
    subcmd_data = nil
    if ary = @subcommand.assoc(subcmd)
      subcmd_data = ary[1]
    end
    subcmd_data
  end
  private :get_subcmd_data

  def get_option_parser(subcmd, subcmd_data)
    opt = OptionParserForSubCmd.new(get_banner(subcmd_data), *@args_option_parser)
    opt.subcommand_name = subcmd
    if subcmd_data && subcmd_data[:setting]
      subcmd_data[:setting].call(opt)
    end
    if @global_option_setting && (!subcmd_data || subcmd_data[:load_global_options])
      @global_option_setting.call(opt)
    end
    opt
  end
  private :get_option_parser

  def message_list_subcommands(opt)
    mes = "Subcommands of #{opt.program_name}:\n"
    @subcommand.each do |name, val|
      mes << "    " << name << "\n"
    end
    mes
  end
  private :message_list_subcommands

  def parse!(argv = ARGV)
    if @help_subcommand_use_p
      subcommand("help", :load_global_options => false)
    end

    subcmd = argv[0]
    if subcmd_data = get_subcmd_data(subcmd)
      argv.shift
    else
      subcmd = nil
    end
    opt = get_option_parser(subcmd, subcmd_data)
    opt.parse!(argv)

    if @help_subcommand_use_p && subcmd == "help"
      print opt.to_s + "\n"
      puts message_list_subcommands(opt)
      exit
    end

    subcmd
  end
end

require "subcommand_optparse/version"
require "optparse"
require "active_support/core_ext/array/extract_options"

class SubCmdOptParser
  class OptionParserForSubCmd < OptionParser
    attr_accessor :subcommand_name
    attr_accessor :description
    attr_accessor :summary
    attr_writer :usage
    attr_writer :example

    def initialize(subcmd, description, width, indent)
      @subcommand_name = subcmd
      @description = description
      @summary = nil
      super(nil, width, indent)
    end

    def usage
      usage_str = "Usage: "
      if @usage
        @usage.each_line.with_index do |line, ind|
          usage_str << "       " if ind > 0
          usage_str << line.sub(/\n?\z/, "\n")
        end
      else
        usage_str << "#{program_name} #{@subcommand_name || '<command>'} [options]\n"
      end
      usage_str
    end

    def banner
      unless @banner
        @banner = usage
        if @summary
          @banner << "\n#{@summary.sub(/\n?\z/, "\n")}"
        elsif @description
          @banner << "\n#{@description.sub(/\n?\z/, "\n")}"
        end
        if @example
          if @example.each_line.count == 1
            @banner << "\nExample: #{@example.strip}"
          else
            @banner << "\nExamples:\n"
            @example.each_line do |line|
              @banner << "    #{line.sub(/\n?\z/, "\n")}"
            end
          end
        end
      end
      @banner
    end

    def help
      str_banner = "#{banner}".sub(/\n?\z/, "\n")
      str_summary =  summarize("")
      if str_summary.size > 0
        str_banner << "\nOptions:\n"
      end
      str_banner + str_summary
    end

    alias_method :to_s, :help
  end

  # summary is shows in help message
  attr_accessor :summary
  attr_accessor :program_name
  attr_accessor :summary_width
  attr_accessor :summary_indent
  attr_accessor :version
  attr_accessor :release
  alias set_program_name program_name=
  alias set_summary_width summary_width=
  alias set_summary_indent summary_indent=

  # @overload initialize(width = 32, indent = ' ' * 4, opts = {})
  #  @param [Fixnum] width Width of summary
  #  @param [String] indent Indent of summary
  #  @param [Hash] opts Options hash
  #  @option opts [boolean] :help_command
  #      If the value is false then command "help" is not set automatically. Default is true
  #  @option opts [boolean] :version_command
  #      If the value is false then command "version" is not set automatically. Default is true
  #  @option opts [boolean] :accept_undefined_command
  #      If the value is false then show help for undefined commands. Default is false
  #  @option opts [boolean] :parse_only
  #      Commands (help and version) do not exit with printing messages and just parse options
  #  @yield [sc]
  #  @yieldparam [SubCmdOptParser] sc Option parser
  def initialize(*args, &block)
    opts = args.extract_options!
    @summary_width = args[0] || 32
    @summary_indent = args[1] ||  ' ' * 4
    @global_option_setting = nil
    @subcommand = []
    @help_subcommand_use_p = (!opts.has_key?(:help_command) || opts[:help_command])
    @summary = nil
    @version_subcommand_use_p = (!opts.has_key?(:version_command) || opts[:version_command])
    @accept_undefined_command = opts[:accept_undefined_command]
    @parse_only = opts[:parse_only]
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
    if subcommand_defined?(name)
      raise ArgumentError, "Command '#{name}' has been already defined"
    end
    opts = args.extract_options!
    description = args.shift
    if args.size > 0
      raise ArgumentError, "Too many arguments"
    end
    h = { :description => description, :setting => block }
    h[:load_global_options] = !(opts.has_key?(:load_global_options) && !opts[:load_global_options])
    @subcommand << [name, h]
  end

  def subcommand_clear(name)
    @subcommand.delete_if do |subcmd, data|
      subcmd == name
    end
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
    opt.version = version if @version
    opt.release = release if @release
    subcmd_data[:setting].call(opt) if subcmd_data && subcmd_data[:setting]
    if @global_option_setting && (!subcmd_data || subcmd_data[:load_global_options])
      @global_option_setting.call(opt)
    end
    opt
  end
  private :get_option_parser

  def message_list_subcommands
    mes = "Commands:\n"
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
    mes = "Usage: #{opt.program_name} <command> [options]\n\n"
    if @summary
      mes << @summary << "\n\n"
    end
    mes << message_list_subcommands
    mes
  end
  private :get_banner_help

  def define_prepared_command
    if @help_subcommand_use_p
      unless subcommand_defined?("help")
        subcommand("help", "Show help message", :load_global_options => false) do |opt|
          opt.banner = get_banner_help(opt)
        end
      end
    end
    if @version_subcommand_use_p
      unless subcommand_defined?("version")
        subcommand("version", "Show version", :load_global_options => false)
      end
    end
  end
  private :define_prepared_command

  def exec_prepared_command(opt, argv)
    unless @parse_only
      case opt.subcommand_name
      when "help"
        if !argv.empty?
          if !subcommand_defined?(argv[0])
            puts "Unknown command: #{argv[0].inspect}"
          else
            opt = get_option_parser(argv[0], get_subcmd_data(argv[0]))
          end
        end
        print opt.to_s
        return true
      when "version"
        puts opt.ver || "Unknown version"
        return true
      end
    end
    nil
  end
  private :exec_prepared_command

  def parse!(argv = ARGV)
    define_prepared_command
    subcmd = argv[0]
    if subcmd_data = get_subcmd_data(subcmd)
      argv.shift
    else
      subcmd = nil
      unless @accept_undefined_command
        subcmd = "help"
        unless subcmd_data = get_subcmd_data(subcmd)
          raise "Unknown command #{subcmd.inspect}"
        end
      end
    end
    opt = get_option_parser(subcmd, subcmd_data)
    if exec_prepared_command(opt, argv)
      exit(0)
    end
    opt.parse!(argv)
    subcmd
  end
end

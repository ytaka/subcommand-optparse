$: << File.join(File.dirname(__dir__), "lib")
require "subcommand_optparse"

options = {}

parser = SubCmdOptParser.new(:help_command => true) do |sc|
  sc.program_name = "sample_command.rb"
  sc.version = "0.0.1"
  sc.release = "hello world"

  sc.global_option do |opt|
    opt.on("--global-option", "Banner of global option") do |v|
      options[:global_option] = true
    end
  end
  sc.subcommand("foo", "Description of foo") do |opt|
    opt.on("--foo-option", "Foo option") do |v|
      options[:foo] = true
    end
  end
  sc.subcommand("bar") do |opt|
    opt.on("--bar-option", "Description of bar") do |v|
      options[:bar] = true
    end
  end
end
subcmd = parser.parse!

p subcmd
p options

require "spec_helper"

describe SubCmdOptParser do
  it "should raise error" do
    opt = SubCmdOptParser.new do |opt_subcmd|
      opt_subcmd.subcommand("hello")
      expect do
        opt_subcmd.subcommand("hello")
      end.to raise_error
    end
  end

  context "when executing prepared commands" do
    before(:each) do
      $stdout = StringIO.new
    end

    it "should exit in help command" do
      opt = SubCmdOptParser.new
      expect do
        opt.parse!(["help"])
      end.to raise_error(SystemExit)
    end

    it "should exit in version command" do
      opt = SubCmdOptParser.new
      expect do
        opt.parse!(["version"])
      end.to raise_error(SystemExit)
    end

    it "should not exit in help command" do
      opt = SubCmdOptParser.new(:parse_only => true)
      expect do
        opt.parse!(["help"])
      end.not_to raise_error
    end

    it "should not exit in version command" do
      opt = SubCmdOptParser.new(:parse_only => true)
      expect do
        opt.parse!(["version"])
      end.not_to raise_error
    end

    after(:each) do
      $stdout = STDOUT
    end
  end
end

require 'spec_helper'
require 'timecop'

describe Mang do
  it 'has a version number' do
    refute_nil ::Mang::VERSION
  end

  describe 'when device is not a TTY' do
    before do
      @io = StringIO.new
    end

    describe '#log without namespace' do
      before do
        @logger = Mang::Logger.new(nil, @io)
      end

      it 'logs message' do
        Timecop.freeze(Time.now) do
          @logger.log('my message')
          assert_equal "#{Time.now} my message\n", @io.string
        end
      end

      it 'logs message from block' do
        Timecop.freeze(Time.now) do
          @logger.log { 'my message' }
          assert_equal "#{Time.now} my message\n", @io.string
        end
      end
    end

    describe '#log with default namespace' do
      before do
        @logger = Mang::Logger.new(:main, @io)
      end

      it 'logs message with default namespace' do
        Timecop.freeze(Time.now) do
          @logger.log('my message')
          assert_equal "#{Time.now} [main] my message\n", @io.string
        end
      end

      it 'logs message from block with default namespace' do
        Timecop.freeze(Time.now) do
          @logger.log { 'my message' }
          assert_equal "#{Time.now} [main] my message\n", @io.string
        end
      end
    end
  end

  describe 'when device is a TTY' do
    def line_re(ns, msg)
      if ns
        /\e\[\d+;\d+m#{ns}\e\[0m \e\[\d+;\d+m#{msg}\e\[0m \+\d+[ms]+/
      else
        /\e\[\d+;\d+m#{msg}\e\[0m \+\d+[ms]+/
      end
    end

    before do
      @io = TtyMockIO.new
    end

    describe '#log without namespace' do
      before do
        @logger = Mang::Logger.new(nil, @io)
      end

      it 'logs message' do
        @logger.log('my message')
        assert_match line_re(nil, 'my message'), @io.string
      end

      it 'logs message from block' do
        @logger.log { 'my message' }
        assert_match line_re(nil, 'my message'), @io.string
      end
    end

    describe '#log with default namespace' do
      before do
        @logger = Mang::Logger.new(:main, @io)
      end

      it 'logs message with default namespace' do
        @logger.log('my message')
        assert_match line_re('main', 'my message'), @io.string
      end

      it 'logs message from block with default namespace' do
        @logger.log { 'my message' }
        assert_match line_re('main', 'my message'), @io.string
      end
    end
  end

  class TtyMockIO < StringIO
    def isatty
      true
    end
  end
end

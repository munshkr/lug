require 'spec_helper'
require 'timecop'

describe Lug do
  it 'has a version number' do
    refute_nil ::Lug::VERSION
  end

  describe '#initialize' do
    it 'defaults to no namespace and STDERR io' do
      lug = Lug.create
      assert_nil lug.namespace
      assert_equal STDERR, lug.io
    end
  end

  describe '#on' do
    describe 'without default namespace' do
      before do
        @io = StringIO.new
        @lug = Lug.create(nil, @io)
      end

      it 'clones logger with namespace appended to default' do
        lug = @lug.on(:script)

        assert_instance_of Lug::Logger, lug
        assert_equal @lug.io.object_id, lug.io.object_id
        assert_equal 'script', lug.namespace
      end
    end

    describe 'with default namespace' do
      before do
        @io = StringIO.new
        @lug = Lug.create(:main, @io)
      end

      it 'clones logger with namespace' do
        lug = @lug.on(:script)

        assert_instance_of Lug::Logger, lug
        assert_equal @lug.io.object_id, lug.io.object_id
        assert_equal 'main:script', lug.namespace
      end
    end
  end

  describe '#log' do
    describe 'when device is not a TTY' do
      before do
        @io = StringIO.new
      end

      describe 'without namespace' do
        before do
          @lug = Lug.create(nil, @io)
        end

        it 'logs message' do
          Timecop.freeze(Time.now) do
            @lug.log('my message')
            assert_equal "#{Time.now} my message\n", @io.string
          end
        end

        it 'logs message from block' do
          Timecop.freeze(Time.now) do
            @lug.log { 'my message' }
            assert_equal "#{Time.now} my message\n", @io.string
          end
        end
      end

      describe 'with default namespace' do
        before do
          @lug = Lug.create(:main, @io)
        end

        it 'logs message with default namespace' do
          Timecop.freeze(Time.now) do
            @lug.log('my message')
            assert_equal "#{Time.now} [main] my message\n", @io.string
          end
        end

        it 'logs message from block with default namespace' do
          Timecop.freeze(Time.now) do
            @lug.log { 'my message' }
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

      describe 'without namespace' do
        before do
          @lug = Lug.create(nil, @io)
        end

        it 'logs message' do
          @lug.log('my message')
          assert_match line_re(nil, 'my message'), @io.string
        end

        it 'logs message from block' do
          @lug.log { 'my message' }
          assert_match line_re(nil, 'my message'), @io.string
        end
      end

      describe 'with default namespace' do
        before do
          @lug = Lug.create(:main, @io)
        end

        it 'logs message with default namespace' do
          @lug.log('my message')
          assert_match line_re('main', 'my message'), @io.string
        end

        it 'logs message from block with default namespace' do
          @lug.log { 'my message' }
          assert_match line_re('main', 'my message'), @io.string
        end
      end
    end
  end

  describe '#<<' do
    before do
      @io = StringIO.new
      @lug = Lug.create(nil, @io)
    end

    it 'is an alias of #log' do
      @lug.log 'message'
      res_log = @io.string

      @io.truncate(0)

      @lug << 'message'
      res = @io.string

      assert_equal res_log, res
    end
  end

  class TtyMockIO < StringIO
    def isatty
      true
    end
  end
end

require 'spec_helper'
require 'timecop'

describe Lug::TtyLogger do
  before do
    @io = TtyMockIO.new
  end

  describe '#log' do
  end

  describe '#log' do
    before do
      @logger = Lug::TtyLogger.new(@io)
    end

    describe 'without +namespace+' do
      it 'logs message' do
        @logger.log('my message')
        assert_match line_re(nil, 'my message'), @io.string
      end

      it 'logs message from block' do
        @logger.log { 'my message' }
        assert_match line_re(nil, 'my message'), @io.string
      end

      it 'logs +message+ if not nil, even if a block is given' do
        @logger.log('my message') { 'another message' }
        assert_match line_re(nil, 'my message'), @io.string
      end
    end

    describe 'with +namespace+' do
      it 'logs message with default namespace' do
        @logger.log('my message', :main)
        assert_match line_re('main', 'my message'), @io.string
      end

      it 'logs message from block with default namespace' do
        @logger.log(nil, :main) { 'my message' }
        assert_match line_re('main', 'my message'), @io.string
      end
    end
  end
end

def line_re(ns, msg)
  if ns
    /\e\[\d+;\d+m#{ns}\e\[0m \e\[\d+;\d+m#{msg}\e\[0m \+\d+[ms]+/
  else
    /\e\[\d+;\d+m#{msg}\e\[0m \+\d+[ms]+/
  end
end

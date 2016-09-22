require 'spec_helper'

describe Lug::Namespace do
  before do
    @io = StringIO.new
    ENV['DEBUG'] = '*'
  end

  describe '#initialize' do
    it 'accepts a +namespace+ string and a +logger+ instance' do
      logger = Lug::Logger.new(@io)
      ns = Lug::Namespace.new(logger, :main)

      assert_equal 'main', ns.namespace
      assert_equal logger, ns.logger
    end
  end

  describe '#on' do
    it 'creates another Namespace with +namespace+ appended' do
      @ns = Lug::Logger.new(@io).on(:main)
      ns = @ns.on(:script)

      assert_instance_of Lug::Namespace, ns
      assert_equal @ns.logger, ns.logger
      assert_equal 'main:script', ns.namespace
    end
  end

  describe '#log' do
    before do
      @ns = Lug::Logger.new(@io).on(:main)
    end

    it 'logs message' do
      Timecop.freeze(Time.now) do
        @ns.log('my message')
        assert_equal "#{Time.now} #{$$} [main] my message\n", @io.string
      end
    end

    it 'logs message from block' do
      Timecop.freeze(Time.now) do
        @ns.log { 'my message' }
        assert_equal "#{Time.now} #{$$} [main] my message\n", @io.string
      end
    end
  end
end

require 'spec_helper'

describe Lug::Logger do
  before do
    @io = StringIO.new
    ENV['DEBUG'] = '*'
  end

  after do
    ENV.delete('DEBUG')
  end

  describe '#initialize' do
    before do
      @device = Lug::Device.new(@io)
    end

    it 'accepts a +device+ instance and a +namespace+ string' do
      logger = Lug::Logger.new(@device, :main)

      assert_equal 'main', logger.namespace
      assert_equal @device, logger.device
    end

    it '+namespace+ can be nil' do
      logger = Lug::Logger.new(@device)

      assert_nil logger.namespace
      assert_equal @device, logger.device
    end
  end

  describe '#log' do
    before do
      @logger = Lug::Device.new(@io).on(:main)
    end

    it 'logs message' do
      Timecop.freeze(Time.now) do
        @logger.log('my message')
        assert_equal "#{Time.now} #{$$} [main] my message\n", @io.string
      end
    end

    it 'logs message from block' do
      Timecop.freeze(Time.now) do
        @logger.log { 'my message' }
        assert_equal "#{Time.now} #{$$} [main] my message\n", @io.string
      end
    end

    it 'logs +message+ if not nil, even if a block is given' do
      Timecop.freeze(Time.now) do
        @logger.log('my message') { 'another message' }
        assert_equal "#{Time.now} #{$$} [main] my message\n", @io.string
      end
    end
  end

  describe '#on' do
    it 'creates another Namespace with +namespace+ appended' do
      @logger = Lug::Device.new(@io).on(:main)
      logger = @logger.on(:script)

      assert_instance_of Lug::Logger, logger
      assert_equal @logger.device, logger.device
      assert_equal 'main:script', logger.namespace
    end
  end

  describe '#enabled?' do
    before do
      ENV['DEBUG'] = 'foo'
    end

    after do
      ENV.delete('DEBUG')
    end

    it 'is true if logger has that namespace enabled' do
      assert Lug::Device.new(@io).on(:foo).enabled?
      refute Lug::Device.new(@io).on(:bar).enabled?
    end
  end
end

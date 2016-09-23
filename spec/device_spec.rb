require 'spec_helper'

describe Lug::Device do
  before do
    @io = StringIO.new
  end

  describe '#initialize' do
    it 'creates a device with stderr as default IO' do
      device = Lug::Device.new
      assert_equal STDERR, device.io
    end

    it 'accepts an optional +io+ parameter' do
      device = Lug::Device.new(@io)
      assert_equal @io, device.io
    end

    it 'calls #enable with DEBUG env variable if set' do
      ENV['DEBUG'] = 'foo'

      device = Lug::Device.new
      assert device.enabled_for?(:foo)
      refute device.enabled_for?(:bar)
    end
  end

  describe '#log' do
    before do
      @device = Lug::Device.new(@io)
    end

    it 'logs message' do
      Timecop.freeze(Time.now) do
        @device.log('my message')
        assert_equal "#{Time.now} #{$$} my message\n", @io.string
      end
    end

    it 'logs message with namespace' do
      Timecop.freeze(Time.now) do
        @device.log('my message', :main)
        assert_equal "#{Time.now} #{$$} [main] my message\n", @io.string
      end
    end
  end

  describe '#on' do
    it 'creates a Logger thats wraps device with +namespace+' do
      device = Lug::Device.new(@io)
      logger = device.on(:script)

      assert_instance_of Lug::Logger, logger
      assert_equal device, logger.device
      assert_equal 'script', logger.namespace
    end
  end

  describe '#<<' do
    it 'is an alias of #log' do
      device = Lug::Device.new(@io)
      device.log 'message'
      res_log = @io.string

      @io.truncate(0)

      device << 'message'
      res = @io.string

      assert_equal res_log, res
    end
  end
end

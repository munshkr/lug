require 'spec_helper'

describe Lug do
  it 'has a version number' do
    refute_nil Lug::VERSION
  end

  describe '.create' do
    describe 'when +namespace+ is present' do
      it 'returns a new Logger with a TtyDevice' do
        logger = Lug.create('main', TtyMockIO.new)

        assert_instance_of Lug::Logger, logger
        assert_equal 'main', logger.namespace
        assert_instance_of Lug::TtyDevice, logger.device
      end

      it 'creates a new Namespace with a Logger' do
        logger = Lug.create('main', StringIO.new)

        assert_instance_of Lug::Logger, logger
        assert_equal 'main', logger.namespace
        assert_instance_of Lug::Device, logger.device
      end
    end

    it 'defaults to TtyDevice and stderr IO' do
      logger = Lug.create
      assert_instance_of Lug::Logger, logger
      assert_nil logger.namespace
      assert_instance_of Lug::TtyDevice, logger.device
      assert_equal STDERR, logger.device.io
    end
  end
end

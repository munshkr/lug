require 'spec_helper'

describe Lug do
  it 'has a version number' do
    refute_nil Lug::VERSION
  end

  describe '.create' do
    describe 'when +namespace+ is present' do
      it 'returns a new Namespace with a TtyLogger' do
        lug = Lug.create('main', TtyMockIO.new)

        assert_instance_of Lug::Namespace, lug
        assert_equal 'main', lug.namespace
        assert_instance_of Lug::TtyLogger, lug.logger
      end

      it 'creates a new Namespace with a Logger' do
        lug = Lug.create('main', StringIO.new)

        assert_instance_of Lug::Namespace, lug
        assert_equal 'main', lug.namespace
        assert_instance_of Lug::Logger, lug.logger
      end
    end

    it 'defaults to TtyLogger and stderr IO' do
      lug = Lug.create
      assert_instance_of Lug::TtyLogger, lug
      assert_equal STDERR, lug.io
    end
  end
end

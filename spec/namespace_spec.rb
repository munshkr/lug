require 'spec_helper'

describe Lug::Namespace do
  before do
    @io = StringIO.new
    ENV['DEBUG'] = '*'
  end

  after do
    ENV.delete('DEBUG')
  end

  describe '#initialize' do
    it 'accepts a +logger+ instance and a +namespace+ string' do
      logger = Lug::Logger.new(@io)
      ns = Lug::Namespace.new(logger, :main)

      assert_equal 'main', ns.namespace
      assert_equal logger, ns.logger
    end

    it '+namespace+ can be nil' do
      logger = Lug::Logger.new(@io)
      ns = Lug::Namespace.new(logger)

      assert_nil ns.namespace
      assert_equal logger, ns.logger
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

    it 'logs +message+ if not nil, even if a block is given' do
      Timecop.freeze(Time.now) do
        @ns.log('my message') { 'another message' }
        assert_equal "#{Time.now} #{$$} [main] my message\n", @io.string
      end
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

  describe '#enabled?' do
    before do
      ENV['DEBUG'] = 'foo'
    end

    after do
      ENV.delete('DEBUG')
    end

    it 'is true if logger has that namespace enabled' do
      assert Lug::Logger.new(@io).on(:foo).enabled?
      refute Lug::Logger.new(@io).on(:bar).enabled?
    end
  end
end

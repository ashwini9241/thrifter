require_relative '../test_helper'

class RpcMetricsTest < MiniTest::Unit::TestCase
  attr_reader :rpc

  def setup
    super

    @rpc = Thrifter::RPC.new(:foo, :args)
  end

  def test_happy_path
    app = stub
    app.stubs(:call).with(rpc)

    statsd = mock
    statsd.expects(:time).with("rpc.#{rpc.name}.latency").yields.returns(:response)
    statsd.expects(:increment).with("rpc.#{rpc.name}.outgoing")
    statsd.expects(:increment).with("rpc.#{rpc.name}.success")

    middleware = Thrifter::RpcMetrics.new app, statsd
    result = middleware.call rpc

    assert :response == result, 'Return value incorrect'
  end

  def test_counts_unknown_transport_exceptions_and_reraises
    app = stub
    app.stubs(:call).with(rpc).raises(Thrift::TransportException.new(
      Thrift::TransportException::UNKNOWN
    ))

    statsd = mock
    statsd.expects(:time).yields
    statsd.expects(:increment).with("rpc.#{rpc.name}.error.transport.unknown")
    statsd.expects(:increment).with("rpc.#{rpc.name}.outgoing")
    statsd.expects(:increment).with("rpc.#{rpc.name}.error")

    middleware = Thrifter::RpcMetrics.new app, statsd

    assert_raises Thrift::TransportException do
      middleware.call rpc
    end
  end

  def test_counts_not_open_transport_exceptions_and_reraises
    app = stub
    app.stubs(:call).with(rpc).raises(Thrift::TransportException.new(
      Thrift::TransportException::NOT_OPEN
    ))

    statsd = mock
    statsd.expects(:time).yields
    statsd.expects(:increment).with("rpc.#{rpc.name}.error.transport.not_open")
    statsd.expects(:increment).with("rpc.#{rpc.name}.outgoing")
    statsd.expects(:increment).with("rpc.#{rpc.name}.error")

    middleware = Thrifter::RpcMetrics.new app, statsd

    assert_raises Thrift::TransportException do
      middleware.call rpc
    end
  end

  def test_counts_already_open_transport_exceptions_and_reraises
    app = stub
    app.stubs(:call).with(rpc).raises(Thrift::TransportException.new(
      Thrift::TransportException::ALREADY_OPEN
    ))

    statsd = mock
    statsd.expects(:time).yields
    statsd.expects(:increment).with("rpc.#{rpc.name}.error.transport.already_open")
    statsd.expects(:increment).with("rpc.#{rpc.name}.outgoing")
    statsd.expects(:increment).with("rpc.#{rpc.name}.error")

    middleware = Thrifter::RpcMetrics.new app, statsd

    assert_raises Thrift::TransportException do
      middleware.call rpc
    end
  end

  def test_counts_timed_out_transport_exceptions_and_reraises
    app = stub
    app.stubs(:call).with(rpc).raises(Thrift::TransportException.new(
      Thrift::TransportException::TIMED_OUT
    ))

    statsd = mock
    statsd.expects(:time).yields
    statsd.expects(:increment).with("rpc.#{rpc.name}.error.transport.timeout")
    statsd.expects(:increment).with("rpc.#{rpc.name}.outgoing")
    statsd.expects(:increment).with("rpc.#{rpc.name}.error")

    middleware = Thrifter::RpcMetrics.new app, statsd

    assert_raises Thrift::TransportException do
      middleware.call rpc
    end
  end

  def test_counts_eof_transport_exceptions_and_reraises
    app = stub
    app.stubs(:call).with(rpc).raises(Thrift::TransportException.new(
      Thrift::TransportException::END_OF_FILE
    ))

    statsd = mock
    statsd.expects(:time).yields
    statsd.expects(:increment).with("rpc.#{rpc.name}.error.transport.eof")
    statsd.expects(:increment).with("rpc.#{rpc.name}.outgoing")
    statsd.expects(:increment).with("rpc.#{rpc.name}.error")

    middleware = Thrifter::RpcMetrics.new app, statsd

    assert_raises Thrift::TransportException do
      middleware.call rpc
    end
  end

  def test_counts_protocol_exceptions
    app = stub
    app.stubs(:call).with(rpc).raises(Thrift::ProtocolException)

    statsd = mock
    statsd.expects(:time).yields
    statsd.expects(:increment).with("rpc.#{rpc.name}.error.protocol")
    statsd.expects(:increment).with("rpc.#{rpc.name}.outgoing")
    statsd.expects(:increment).with("rpc.#{rpc.name}.error")

    middleware = Thrifter::RpcMetrics.new app, statsd

    assert_raises Thrift::ProtocolException do
      middleware.call rpc
    end
  end

  def test_counts_application_exceptions
    app = stub
    app.stubs(:call).with(rpc).raises(Thrift::ApplicationException)

    statsd = mock
    statsd.expects(:time).yields
    statsd.expects(:increment).with("rpc.#{rpc.name}.error.application")
    statsd.expects(:increment).with("rpc.#{rpc.name}.outgoing")
    statsd.expects(:increment).with("rpc.#{rpc.name}.error")

    middleware = Thrifter::RpcMetrics.new app, statsd

    assert_raises Thrift::ApplicationException do
      middleware.call rpc
    end
  end

  def test_counts_timeouts
    app = stub
    app.stubs(:call).with(rpc).raises(Timeout::Error)

    statsd = mock
    statsd.expects(:time).yields
    statsd.expects(:increment).with("rpc.#{rpc.name}.error.timeout")
    statsd.expects(:increment).with("rpc.#{rpc.name}.outgoing")
    statsd.expects(:increment).with("rpc.#{rpc.name}.error")

    middleware = Thrifter::RpcMetrics.new app, statsd

    assert_raises Timeout::Error do
      middleware.call rpc
    end
  end

  def test_counts_other_errors
    app = stub
    app.stubs(:call).with(rpc).raises(StandardError)

    statsd = mock
    statsd.expects(:time).yields
    statsd.expects(:increment).with("rpc.#{rpc.name}.error.other")
    statsd.expects(:increment).with("rpc.#{rpc.name}.outgoing")
    statsd.expects(:increment).with("rpc.#{rpc.name}.error")

    middleware = Thrifter::RpcMetrics.new app, statsd

    assert_raises StandardError do
      middleware.call rpc
    end
  end
end

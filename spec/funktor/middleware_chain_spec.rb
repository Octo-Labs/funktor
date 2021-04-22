RSpec.describe Funktor::MiddlewareChain do
  class TestMiddleware
    def initialize(history_array)
      @history_array = history_array
    end
    def call(*args)
      @history_array.push "#{self.class.name} before"
      yield
      @history_array.push "#{self.class.name} after"
    end
  end

  class AnotherTestMiddleware < TestMiddleware
  end

  class PreventMiddleware
    def initialize(history_array)
      @history_array = history_array
    end
    def call(*args)
      @history_array.push "#{self.class.name}"
    end
  end

  describe 'add' do
    it 'can add a middleware to the entries array' do
      chain = Funktor::MiddlewareChain.new
      chain.add TestMiddleware
      expect(chain.entries.count).to eq(1)
    end
    it 'will not add a duplicate middleware to the entries array' do
      chain = Funktor::MiddlewareChain.new
      2.times{ chain.add TestMiddleware }
      expect(chain.entries.count).to eq(1)
    end
  end

  describe 'remove' do
    it 'can remove a middleware from the entries array' do
      chain = Funktor::MiddlewareChain.new
      chain.add TestMiddleware
      expect(chain.entries.count).to eq(1)
      chain.remove TestMiddleware
      expect(chain.entries.count).to eq(0)
    end
  end

  describe 'insert_before' do
    it 'can insert at the right place' do
      chain = Funktor::MiddlewareChain.new
      chain.add TestMiddleware
      chain.add AnotherTestMiddleware
      chain.insert_before AnotherTestMiddleware, PreventMiddleware
      expect(chain.entries.map(&:klass)).to eq([TestMiddleware, PreventMiddleware, AnotherTestMiddleware])
    end
  end

  describe 'insert_after' do
    it 'can insert at the right place' do
      chain = Funktor::MiddlewareChain.new
      chain.add TestMiddleware
      chain.add AnotherTestMiddleware
      chain.insert_after TestMiddleware, PreventMiddleware
      expect(chain.entries.map(&:klass)).to eq([TestMiddleware, PreventMiddleware, AnotherTestMiddleware])
    end
  end

  describe 'invoke' do
    it 'will call a middleware and then yield to a block' do
      history = []
      chain = Funktor::MiddlewareChain.new
      chain.add TestMiddleware, history
      chain.invoke do
        history.push "test block"
      end
      expect(history).to eq([
        "TestMiddleware before",
        "test block",
        "TestMiddleware after"
      ])
    end

    it 'will call several middlewares and then yield to a block' do
      history = []
      chain = Funktor::MiddlewareChain.new
      chain.add TestMiddleware, history
      chain.add AnotherTestMiddleware, history
      chain.invoke do
        history.push "test block"
      end
      expect(history).to eq([
        "TestMiddleware before",
        "AnotherTestMiddleware before",
        "test block",
        "AnotherTestMiddleware after",
        "TestMiddleware after"
      ])
    end

    it 'will allow a middleware in the middle of the chain to prevent the yield to a block' do
      history = []
      chain = Funktor::MiddlewareChain.new
      chain.add TestMiddleware, history
      chain.add PreventMiddleware, history
      chain.add AnotherTestMiddleware, history
      chain.invoke do
        history.push "test block"
      end
      expect(history).to eq([
        "TestMiddleware before",
        "PreventMiddleware",
        "TestMiddleware after"
      ])
    end

    it 'will yield to a block when the chain is empty' do
      chain = Funktor::MiddlewareChain.new
      test_block_called = false
      chain.invoke do
        test_block_called = true
      end
      expect(test_block_called).to be_truthy
    end
  end
end

RSpec.describe Funktor::MiddlewareChain do
  it 'will yield to a block when the chain is empty' do
    chain = Funktor::MiddlewareChain.new
    test_block_called = false
    chain.invoke do
      test_block_called = true
    end
    expect(test_block_called).to be_truthy
  end
end

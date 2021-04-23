RSpec.describe Funktor do
  it "has a version number" do
    expect(Funktor::VERSION).not_to be nil
  end

  class EmptyMiddleware; end

  describe 'job_pusher_middleware' do
    it 'returns a MiddleWareChain' do
      expect(Funktor.job_pusher_middleware).to be_a(Funktor::MiddlewareChain)
    end
    it 'is persistent' do
      expect(Funktor.job_pusher_middleware.entries.count).to eq(0)
      Funktor.job_pusher_middleware do |chain|
        chain.add EmptyMiddleware
      end
      expect(Funktor.job_pusher_middleware.entries.count).to eq(1)
    end
  end

  describe 'active_job_handler_middleware' do
    it 'returns a MiddleWareChain' do
      expect(Funktor.active_job_handler_middleware).to be_a(Funktor::MiddlewareChain)
    end
    it 'is persistent' do
      expect(Funktor.active_job_handler_middleware.entries.count).to eq(1)
      Funktor.active_job_handler_middleware do |chain|
        chain.add EmptyMiddleware
      end
      expect(Funktor.active_job_handler_middleware.entries.count).to eq(2)
    end
  end
end

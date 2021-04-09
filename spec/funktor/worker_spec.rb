require 'funktor/worker'
RSpec.describe Funktor::Worker, type: :worker do
  class LambdaTestWorker
    include Funktor::Worker
  end
  let(:params) do
    {}
  end

  describe 'perform_async' do
    it 'delegates to perform_in' do
      expect(LambdaTestWorker).to receive(:perform_in).with(0, params).and_return(nil)
      LambdaTestWorker.perform_async(params)
    end
  end

  describe 'perform_at' do
    it 'delegates to perform_in' do
      expect(LambdaTestWorker).to receive(:perform_in).with(0, params).and_return(nil)
      LambdaTestWorker.perform_at(Time.now - 5*60, params)
    end
  end

  describe 'perform_in' do
    let(:sqs_client){ double Aws::SQS::Client }
    it 'pushes a message onto the incoming job queue' do
      expect(sqs_client).to receive(:send_message).and_return(nil)
      expect(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
      LambdaTestWorker.perform_in(0, {})
    end
  end
end



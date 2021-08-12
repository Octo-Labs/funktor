require 'funktor/worker'
RSpec.describe Funktor::Worker, type: :worker do
  let(:custom_queue_url){ 'http://some-queue-url/' }
  class LambdaTestWorker
    include Funktor::Worker
    funktor_options queue_url: 'http://some-queue-url/'
  end

  class CustomQueueWorker
    include Funktor::Worker
    funktor_options queue: :custom
  end

  let(:params) do
    {}
  end

  describe 'queue_url' do
    it 'can be set at the class level' do
      expect(LambdaTestWorker.queue_url).to eq(custom_queue_url)
    end
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

  describe 'build_job_payload' do
    it "defaults to 'default'" do
      payload = LambdaTestWorker.build_job_payload(0)
      expect(payload[:queue]).to eq 'default'
    end
    it "can be set by a worker" do
      payload = CustomQueueWorker.build_job_payload(0)
      expect(payload[:queue]).to eq 'custom'
    end
  end
end



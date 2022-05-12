require 'funktor/worker'
require 'timecop'
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

  class DescendantWorker < CustomQueueWorker
    funktor_options queue: :descendant
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
    let(:sqs_client){ double Aws::SQS::Client }
    it 'delegates to perform_in' do
      expect(sqs_client).to receive(:send_message).and_return(nil)
      expect(Funktor).to receive(:sqs_client).and_return(sqs_client)
      LambdaTestWorker.perform_at(Time.now.utc + 5*60, params)
    end
  end

  describe 'perform_in' do
    it 'delegates to perform_at' do
      Timecop.freeze do
        expect(LambdaTestWorker).to receive(:perform_at).with(Time.now.utc, params).and_return(nil)
        LambdaTestWorker.perform_in(0, {})
      end
    end
  end

  describe 'build_job_payload' do
    it "queue defaults to 'default'" do
      payload = LambdaTestWorker.build_job_payload(Time.now)
      expect(payload[:queue]).to eq 'default'
    end
    it "queue can be set by a worker" do
      payload = CustomQueueWorker.build_job_payload(Time.now)
      expect(payload[:queue]).to eq 'custom'
    end
    it "queue shouldn't leak into a parent class" do
      payload = DescendantWorker.build_job_payload(Time.now)
      expect(payload[:queue]).to eq 'descendant'

      payload = CustomQueueWorker.build_job_payload(Time.now)
      expect(payload[:queue]).to eq 'custom'
    end
  end
end



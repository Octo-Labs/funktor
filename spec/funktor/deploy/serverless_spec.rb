require 'funktor/deploy/serverless'

RSpec.describe Funktor::Deploy::Serverless do
  let(:serverless){ Funktor::Deploy::Serverless.new(**options) }
  let(:file){ 'spec/fixtures/funktor.yml' }
  let(:tmp_dir_prefix){ 'tmp/funktor_deploy_serverless' }
  let(:stage){ 'test' }
  let(:tmp_dir){ "#{tmp_dir_prefix}_#{stage}" }
  let(:options) do
    {
      file: file,
      tmp_dir_prefix: tmp_dir_prefix,
      verbose: true,
      stage: stage
    }
  end
  let(:serverless_file){ File.join tmp_dir, 'serverless.yml' }

  before(:each) do
    FileUtils.rm_rf tmp_dir
  end

  describe 'call' do
    it 'should create a temporary directory, populate it with serverless files, then call serverless' do
      expect(Dir.exist? tmp_dir).to be_falsey
      serverless.call
      expect(Dir.exist? tmp_dir).to be_truthy
      expect(File.exist? serverless_file).to be_truthy
      expect(File.open(serverless_file).read).to match("funktor_test")
    end
  end
end

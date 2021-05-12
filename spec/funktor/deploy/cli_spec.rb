require 'funktor/deploy/cli'

RSpec.describe Funktor::Deploy::CLI do
  let(:cli){ Funktor::Deploy::CLI.new }
  let(:argv){ "-v -f spec/fixtures/funktor.yml -t tmp/funktor_deploy".split }
  let(:expected_args) do
    {
      file: 'spec/fixtures/funktor.yml',
      tmp_dir: 'tmp/funktor_deploy',
      verbose: true
    }
  end

  it "should parse opts and pass the right stuff to Funktor::Deploy::Serverless" do
    expect_any_instance_of(Funktor::Deploy::Serverless).to receive(:call).with(expected_args).and_return(nil)
    cli.parse(argv)
    cli.run
  end
end

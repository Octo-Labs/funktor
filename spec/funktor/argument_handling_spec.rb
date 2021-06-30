require 'funktor/testing'

RSpec.describe Funktor do
  around do |example|
    $received_integer_argument = nil
    $received_string_argument = nil
    Funktor::Testing.inline! do
      example.run
    end
  end

  class ArgumentTestWorker
    include Funktor::Worker
    def perform(integer_argument, string_argument)
      $received_integer_argument = integer_argument
      $received_string_argument = string_argument
    end
  end

  it 'serializes and de-serializes arguments correctly' do
    ArgumentTestWorker.perform_async(42, 'The answer')
    expect($received_integer_argument).to be_a(Integer)
    expect($received_string_argument).to be_a(String)
  end
end

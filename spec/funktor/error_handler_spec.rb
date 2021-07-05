RSpec.describe Funktor::ErrorHandler do
  before :each do
    @error_log = []
  end

  class ErrorHandlerTester
    include Funktor::ErrorHandler
    def call
      raise "fake testing error"
    rescue => error
      handle_error(error)
    end
  end
  describe "handle_error" do
    it "calls a registered blocks" do
      Funktor.error_handlers << proc {|error, context| @error_log.push(error) }
      expect{
        ErrorHandlerTester.new.call
      }.not_to raise_error
      expect(@error_log.count).to eq(1)
      expect(@error_log.first).to be_a(StandardError)
      Funktor.error_handlers.pop
    end
    it "recovers gracefully if a handler raises an error" do
      Funktor.error_handlers << proc {|error, context| raise "handler error" }
      expect{
        ErrorHandlerTester.new.call
      }.not_to raise_error
      expect(@error_log.count).to eq(0)
      Funktor.error_handlers.pop
    end
  end
end

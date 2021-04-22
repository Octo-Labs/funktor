module Funktor
  class MiddlewareChain
    def invoke(*args)
      return yield
    end
  end
end

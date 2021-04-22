module Funktor
  class MiddlewareChain
    attr_reader :entries

    def initialize
      @entries = []
    end

    def remove(klass)
      entries.delete_if { |entry| entry.klass == klass }
    end

    def add(klass, *args)
      remove(klass)
      entries << Entry.new(klass, *args)
    end

    def prepend(klass, *args)
      remove(klass)
      entries.insert(0, Entry.new(klass, *args))
    end

    def insert_before(oldklass, newklass, *args)
      remove(newklass)
      i = entries.index { |entry| entry.klass == oldklass } || 0
      entries.insert(i, Entry.new(newklass, *args))
    end

    def insert_after(oldklass, newklass, *args)
      remove(newklass)
      i = entries.index { |entry| entry.klass == oldklass } || entries.count - 1
      entries.insert(i + 1, Entry.new(newklass, *args))
    end

    def invoke(*args)
      return yield if @entries.empty?

      middlewares = entries.map(&:instantiate)
      traverse_chain = proc do
        if middlewares.empty?
          yield
        else
          middlewares.shift.call(*args, &traverse_chain)
        end
      end
      traverse_chain.call
    end

    class Entry
      attr_reader :klass

      def initialize(klass, *args)
        @klass = klass
        @args = args
      end

      def instantiate
        @klass.new(*@args)
      end
    end
  end
end

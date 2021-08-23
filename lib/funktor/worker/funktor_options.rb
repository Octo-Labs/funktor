require 'active_support/core_ext/class/attribute'

module Funktor
  module Worker
    module FunktorOptions
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          class_attribute :funktor_options_hash
        end
      end
      module ClassMethods
        def funktor_options(options = {})
          self.funktor_options_hash = options
        end

        def get_funktor_options
          self.funktor_options_hash || {}
        end

        def custom_queue_url
          get_funktor_options[:queue_url]
        end

        def custom_queue
          get_funktor_options[:queue]
        end

        def queue_url
          custom_queue_url
        end

        def work_queue
          (self.custom_queue || 'default').to_s
        end
      end
    end
  end
end

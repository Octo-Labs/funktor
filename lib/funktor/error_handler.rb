module Funktor
  module ErrorHandler
    class Logger
      def call(error, context)
        Funktor.logger.warn(Funktor.dump_json(context)) if context
        Funktor.logger.warn("#{error.class.name}: #{error.message}")
        Funktor.logger.warn(error.backtrace.join("\n")) unless error.backtrace.nil?
      end

      Funktor.error_handlers << Funktor::ErrorHandler::Logger.new
    end

    def handle_error(error, context = {})
      Funktor.error_handlers.each do |handler|
        begin
          handler.call(error, context)
        rescue => new_error
          Funktor.logger.error "!!! ERROR HANDLER THREW AN ERROR !!!"
          Funktor.logger.error new_error
          Funktor.logger.error new_error.backtrace.join("\n") unless new_error.backtrace.nil?
        end
      end
    end
  end
end

module Funktor
  class Job
    attr_accessor :job_string
    def initialize(job_string)
      @job_string = job_string
      @job_data = JSON.parse(job_string)
    end

    def worker_class_name
      @job_data["worker"]
    end
  end
end

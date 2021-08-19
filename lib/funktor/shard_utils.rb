module ShardUtils
  def calculate_shard(job_id)
    # TODO : Figure out how/why we could get a missing job_id passed in here...
    job_id ||= ""
    # TODO - Should the number of shards be configurable?
    job_id.sum % 64
  end
end

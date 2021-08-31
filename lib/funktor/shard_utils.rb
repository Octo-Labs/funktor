module ShardUtils
  def calculate_shard(job_id)
    # TODO - Should the number of shards be configurable?
    (job_id.sum % 64).to_s
  end
end

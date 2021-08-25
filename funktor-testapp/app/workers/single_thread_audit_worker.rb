class SingleThreadAuditWorker < AuditWorker
  funktor_options queue: :low_concurrency
end

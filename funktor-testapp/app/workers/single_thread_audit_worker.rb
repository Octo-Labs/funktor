class SingleThreadAuditWorker < AuditWorker
  funktor_options queue: :single_thread
end

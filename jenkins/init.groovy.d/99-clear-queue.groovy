import jenkins.model.*
import hudson.model.*

def logger = { msg -> println "[queue-dedup] ${msg}" }

def cancelDuplicates = { q ->
    def allItems = q.items as List
    if (!allItems) return 0

    def byPR = [:]
    for (item in allItems) {
        def prNum = null
        try {
            for (cause in item.causes) {
                if (cause.getClass().name.contains('GenericCause')) {
                    def field = cause.getClass().getDeclaredField('resolvedVariables')
                    field.setAccessible(true)
                    def vars = field.get(cause) as Map
                    prNum = vars?.PR_NUMBER
                    if (prNum) break
                }
            }
        } catch (Exception e) {}
        def key = prNum ?: "unknown-${item.id}"
        byPR.computeIfAbsent(key) { [] } << item
    }

    int cancelled = 0
    for (entry in byPR.entrySet()) {
        def group = entry.value
        if (group.size() <= 1) continue
        group.sort { it.id }
        def keep = group[0]
        for (int i = 1; i < group.size(); i++) {
            logger "Cancel duplicate: id=${group[i].id} PR=${entry.key} (keep id=${keep.id})"
            q.cancel(group[i].task)
            cancelled++
        }
    }
    cancelled
}

// ── 启动时立即执行 ─────────────────────────────────────────────────
try {
    def queue = Jenkins.instance.queue
    def n = cancelDuplicates(queue)
    logger "Startup: cancelled $n duplicates. Queue size: ${queue.items.size()}"
} catch (Exception e) {
    logger "Startup error: ${e.message}"
}

// ── 每60秒定期清理（防止 webhook 重复触发导致积压） ─────────────────
try {
    def timer = new java.util.Timer('queue-dedup', true)
    timer.scheduleAtFixedRate({
        try {
            def j = Jenkins.instance
            if (j == null || j.isTerminating() || j.isShutdown()) return
            def q = j.queue
            def n = cancelDuplicates(q)
            if (n > 0) logger "Periodic: cancelled $n duplicates"
        } catch (Exception e) {
            logger "Periodic error: ${e.message}"
        }
    }, 60_000L, 60_000L)
    logger "Timer scheduled: running dedup every 60s"
} catch (Exception e) {
    logger "Timer error: ${e.message}"
}

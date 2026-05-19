import Foundation
import CoreServices
import OSLog

/// FSEvents-backed directory watcher that yields a tick on `events` whenever
/// a file under one of the watched roots changes. Drives `AppState.refresh()`.
///
/// The 250ms latency on FSEventStreamCreate naturally debounces rapid bursts.
/// AppState consumes `events` with a `for await` loop; the 60s polling task is
/// kept as a fallback in case FSEvents drops events.
final class FileMonitor: @unchecked Sendable {
    let events: AsyncStream<Void>

    private let continuation: AsyncStream<Void>.Continuation
    private let log = Logger(subsystem: "dev.kokonaut.AIUsageToolbar", category: "FileMonitor")
    private let queue: DispatchQueue
    private var stream: FSEventStreamRef?

    init(queue: DispatchQueue = .global(qos: .utility)) {
        self.queue = queue
        var capturedContinuation: AsyncStream<Void>.Continuation!
        self.events = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        self.continuation = capturedContinuation
    }

    func start(paths: [String]) {
        stop()
        guard !paths.isEmpty else { return }

        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        let cb: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let monitor = Unmanaged<FileMonitor>.fromOpaque(info).takeUnretainedValue()
            monitor.continuation.yield(())
        }

        let flags: FSEventStreamCreateFlags = UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            cb,
            &context,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.25,
            flags
        ) else {
            log.error("failed to create FSEventStream")
            return
        }

        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
        self.stream = stream
        log.debug("started FSEventStream for \(paths.count) path(s)")
    }

    func stop() {
        if let s = stream {
            FSEventStreamStop(s)
            FSEventStreamInvalidate(s)
            FSEventStreamRelease(s)
            stream = nil
        }
    }

    deinit {
        stop()
        continuation.finish()
    }
}

import Foundation
import CoreServices
import OSLog

/// FSEvents-backed directory watcher that yields URLs whenever files under one
/// of the watched roots change. Designed to drive `AppState.refresh()`.
///
/// Not yet wired into `AppState` — v0 uses a 60s polling loop. Switch to this
/// once the parser is exercised against live data.
final class FileMonitor {
    private let log = Logger(subsystem: "dev.kokonaut.AIUsageToolbar", category: "FileMonitor")
    private var stream: FSEventStreamRef?
    private let queue: DispatchQueue
    private let onChange: () -> Void

    init(queue: DispatchQueue = .global(qos: .utility), onChange: @escaping () -> Void) {
        self.queue = queue
        self.onChange = onChange
    }

    func start(paths: [String]) {
        stop()
        guard !paths.isEmpty else { return }

        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        let cb: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let monitor = Unmanaged<FileMonitor>.fromOpaque(info).takeUnretainedValue()
            monitor.onChange()
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
    }
}

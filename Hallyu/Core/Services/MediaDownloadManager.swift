import Foundation
import Observation

enum DownloadState: String, Codable {
    case notDownloaded
    case downloading
    case downloaded
    case failed
}

struct DownloadedMedia: Codable, Identifiable {
    let id: UUID // matches MediaContent id
    let title: String
    let localFileURL: String
    let fileSize: Int64
    let downloadedAt: Date
}

enum MediaDownloadError: Error, LocalizedError {
    case invalidURL
    case insecureScheme
    case untrustedHost(String)
    case invalidResponse
    case fileTooLarge(maxBytes: Int64)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid media URL."
        case .insecureScheme:
            return "Only HTTPS downloads are allowed."
        case .untrustedHost(let host):
            return "Downloads from \(host) are not allowed."
        case .invalidResponse:
            return "The media server returned an invalid response."
        case .fileTooLarge(let maxBytes):
            let max = ByteCountFormatter.string(fromByteCount: maxBytes, countStyle: .file)
            return "This media file exceeds the maximum offline size of \(max)."
        }
    }
}

@Observable
final class MediaDownloadManager: @unchecked Sendable {
    var downloads: [UUID: DownloadState] = [:]
    var downloadProgress: [UUID: Double] = [:]
    var downloadedMedia: [DownloadedMedia] = []
    var totalDownloadSize: Int64 = 0

    private let storageKey = "downloadedMediaItems"
    private let fileManager = FileManager.default
    private let maxDownloadBytes: Int64 = 250 * 1024 * 1024 // 250 MB hard cap
    private let trustedMediaHosts: Set<String> = [
        "commondatastorage.googleapis.com",
        "www.soundhelix.com"
    ]

    init() {
        loadDownloadedMedia()
    }

    // MARK: - Download Management

    func downloadMedia(content: MediaContent) async throws {
        let urlString = content.mediaUrl
        guard !urlString.isEmpty,
              let url = URL(string: urlString) else {
            downloads[content.id] = .failed
            throw MediaDownloadError.invalidURL
        }

        if let existing = localURL(for: content.id) {
            downloads[content.id] = .downloaded
            downloadProgress[content.id] = 1.0
            _ = existing
            return
        }

        try validateDownloadURL(url)

        downloads[content.id] = .downloading
        downloadProgress[content.id] = 0.0

        do {
            let preflightSize: Int64?
            do {
                preflightSize = try await preflightContentLength(for: url)
            } catch let error as MediaDownloadError {
                if case .fileTooLarge = error {
                    throw error
                }
                preflightSize = nil
            } catch {
                preflightSize = nil
            }

            let (tempURL, response) = try await URLSession.shared.download(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                try? fileManager.removeItem(at: tempURL)
                throw MediaDownloadError.invalidResponse
            }

            let responseSize = contentLength(from: httpResponse)
            let fileSize = try validatedFileSize(
                tempURL: tempURL,
                expectedServerSize: preflightSize ?? responseSize
            )

            let localURL = try moveToDocuments(tempURL: tempURL, mediaId: content.id)

            let downloaded = DownloadedMedia(
                id: content.id,
                title: content.title,
                localFileURL: localURL.path,
                fileSize: fileSize,
                downloadedAt: Date()
            )

            removeDuplicateEntries(for: content.id, preserveNewest: false)
            downloadedMedia.append(downloaded)
            downloads[content.id] = .downloaded
            downloadProgress[content.id] = 1.0
            recomputeTotalDownloadSize()
            saveDownloadedMedia()
        } catch {
            downloads[content.id] = .failed
            downloadProgress[content.id] = 0.0
            throw error
        }
    }

    func removeDownload(mediaId: UUID) {
        let matches = downloadedMedia.filter { $0.id == mediaId }
        for media in matches {
            try? fileManager.removeItem(atPath: media.localFileURL)
        }
        downloadedMedia.removeAll { $0.id == mediaId }
        recomputeTotalDownloadSize()
        downloads[mediaId] = .notDownloaded
        downloadProgress.removeValue(forKey: mediaId)
        saveDownloadedMedia()
    }

    func removeAllDownloads() {
        for media in downloadedMedia {
            try? fileManager.removeItem(atPath: media.localFileURL)
        }
        downloadedMedia.removeAll()
        downloads.removeAll()
        downloadProgress.removeAll()
        recomputeTotalDownloadSize()
        saveDownloadedMedia()
    }

    func isDownloaded(mediaId: UUID) -> Bool {
        downloads[mediaId] == .downloaded
    }

    func localURL(for mediaId: UUID) -> URL? {
        guard let media = downloadedMedia.first(where: { $0.id == mediaId }) else {
            return nil
        }
        let url = URL(fileURLWithPath: media.localFileURL)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func downloadState(for mediaId: UUID) -> DownloadState {
        downloads[mediaId] ?? .notDownloaded
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalDownloadSize, countStyle: .file)
    }

    // MARK: - Private

    private var allowedHosts: Set<String> {
        var hosts = trustedMediaHosts
        let config = AppEnvironment.current.supabaseConfig
        if config.isConfigured, let host = config.projectURL.host?.lowercased() {
            hosts.insert(host)
        }
        return hosts
    }

    private func validateDownloadURL(_ url: URL) throws {
        guard url.scheme?.lowercased() == "https" else {
            throw MediaDownloadError.insecureScheme
        }
        guard let host = url.host?.lowercased() else {
            throw MediaDownloadError.invalidURL
        }
        guard allowedHosts.contains(host) else {
            throw MediaDownloadError.untrustedHost(host)
        }
    }

    private func preflightContentLength(for url: URL) async throws -> Int64? {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 15

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MediaDownloadError.invalidResponse
        }

        if httpResponse.statusCode == 405 {
            return nil
        }
        guard (200...399).contains(httpResponse.statusCode) else {
            throw MediaDownloadError.invalidResponse
        }

        if let size = contentLength(from: httpResponse) {
            guard size <= maxDownloadBytes else {
                throw MediaDownloadError.fileTooLarge(maxBytes: maxDownloadBytes)
            }
            return size
        }
        return nil
    }

    private func contentLength(from response: HTTPURLResponse) -> Int64? {
        guard let header = response.value(forHTTPHeaderField: "Content-Length"),
              let length = Int64(header),
              length >= 0 else {
            return nil
        }
        return length
    }

    private func validatedFileSize(tempURL: URL, expectedServerSize: Int64?) throws -> Int64 {
        let sizeFromDisk = (try? fileManager
            .attributesOfItem(atPath: tempURL.path)[.size] as? NSNumber)?
            .int64Value ?? 0
        let candidate = max(sizeFromDisk, expectedServerSize ?? 0)
        guard candidate <= maxDownloadBytes else {
            try? fileManager.removeItem(at: tempURL)
            throw MediaDownloadError.fileTooLarge(maxBytes: maxDownloadBytes)
        }
        return candidate
    }

    private func moveToDocuments(tempURL: URL, mediaId: UUID) throws -> URL {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let mediaDir = documentsDir.appendingPathComponent("OfflineMedia", isDirectory: true)

        if !fileManager.fileExists(atPath: mediaDir.path) {
            try fileManager.createDirectory(at: mediaDir, withIntermediateDirectories: true)
            applyDataProtectionIfAvailable(atPath: mediaDir.path)
        }

        let ext = tempURL.pathExtension.isEmpty ? "mp4" : tempURL.pathExtension
        let destinationURL = mediaDir.appendingPathComponent("\(mediaId.uuidString).\(ext)")

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.moveItem(at: tempURL, to: destinationURL)
        applyDataProtectionIfAvailable(atPath: destinationURL.path)
        return destinationURL
    }

    private func saveDownloadedMedia() {
        guard let data = try? JSONEncoder().encode(downloadedMedia) else { return }
        KeychainHelper.save(data, forKey: storageKey)
    }

    private func loadDownloadedMedia() {
        guard let data = KeychainHelper.load(forKey: storageKey),
              let items = try? JSONDecoder().decode([DownloadedMedia].self, from: data) else {
            return
        }
        downloadedMedia = deduplicatedDownloadedMedia(items)
        recomputeTotalDownloadSize()
        for item in downloadedMedia {
            let exists = fileManager.fileExists(atPath: item.localFileURL)
            downloads[item.id] = exists ? .downloaded : .notDownloaded
        }
    }

    private func removeDuplicateEntries(for mediaId: UUID, preserveNewest: Bool) {
        let matches = downloadedMedia.filter { $0.id == mediaId }
        guard matches.count > 1 || (!matches.isEmpty && !preserveNewest) else { return }
        let sorted = matches.sorted { $0.downloadedAt > $1.downloadedAt }
        let toDelete = preserveNewest ? Array(sorted.dropFirst()) : sorted
        for media in toDelete {
            try? fileManager.removeItem(atPath: media.localFileURL)
        }
        downloadedMedia.removeAll { item in
            toDelete.contains { $0.localFileURL == item.localFileURL && $0.id == item.id }
        }
    }

    private func deduplicatedDownloadedMedia(_ items: [DownloadedMedia]) -> [DownloadedMedia] {
        var bestById: [UUID: DownloadedMedia] = [:]
        for item in items {
            if let existing = bestById[item.id] {
                if item.downloadedAt > existing.downloadedAt {
                    bestById[item.id] = item
                }
            } else {
                bestById[item.id] = item
            }
        }
        return Array(bestById.values)
    }

    private func recomputeTotalDownloadSize() {
        totalDownloadSize = downloadedMedia.reduce(0) { $0 + $1.fileSize }
    }

    private func applyDataProtectionIfAvailable(atPath path: String) {
        #if os(iOS) || os(tvOS) || os(watchOS)
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: path
        )
        #endif
    }
}

import SwiftUI

struct OfflineBanner: View {
    let isOffline: Bool
    let pendingSyncCount: Int

    var body: some View {
        if isOffline {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text("Offline Mode")
                    .font(.caption)
                    .fontWeight(.medium)

                if pendingSyncCount > 0 {
                    Text("(\(pendingSyncCount) pending)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Offline mode. \(pendingSyncCount) changes pending sync.")
        }
    }
}

// MARK: - Claude Offline Fallback

struct ClaudeOfflineFallbackView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("AI Coaching Unavailable")
                .font(.headline)

            Text("Connect to the internet to use AI-powered features. Your review sessions and Hangul lessons still work offline.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI coaching unavailable offline. Review sessions and Hangul lessons still work.")
    }
}

// MARK: - Download Button

struct MediaDownloadButton: View {
    let mediaId: UUID
    let downloadManager: MediaDownloadManager
    let content: MediaContent
    let onDownload: () async -> Void

    var body: some View {
        let state = downloadManager.downloadState(for: mediaId)

        Button {
            Task {
                switch state {
                case .notDownloaded, .failed:
                    await onDownload()
                case .downloaded:
                    downloadManager.removeDownload(mediaId: mediaId)
                case .downloading:
                    break
                }
            }
        } label: {
            HStack(spacing: 6) {
                stateIcon(state)
                stateLabel(state)
            }
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(stateBackground(state))
            .clipShape(Capsule())
        }
        .disabled(state == .downloading)
        .accessibilityLabel(accessibilityDescription(state))
    }

    @ViewBuilder
    private func stateIcon(_ state: DownloadState) -> some View {
        switch state {
        case .notDownloaded:
            Image(systemName: "arrow.down.circle")
                .foregroundStyle(.blue)
        case .downloading:
            ProgressView()
                .controlSize(.mini)
        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.red)
        }
    }

    private func stateLabel(_ state: DownloadState) -> some View {
        switch state {
        case .notDownloaded:
            return Text("Download").foregroundStyle(.blue)
        case .downloading:
            return Text("Downloading...").foregroundStyle(.secondary)
        case .downloaded:
            return Text("Downloaded").foregroundStyle(.green)
        case .failed:
            return Text("Retry").foregroundStyle(.red)
        }
    }

    private func stateBackground(_ state: DownloadState) -> Color {
        switch state {
        case .notDownloaded: return .blue.opacity(0.1)
        case .downloading: return .gray.opacity(0.1)
        case .downloaded: return .green.opacity(0.1)
        case .failed: return .red.opacity(0.1)
        }
    }

    private func accessibilityDescription(_ state: DownloadState) -> String {
        switch state {
        case .notDownloaded: return "Download for offline use"
        case .downloading: return "Downloading"
        case .downloaded: return "Downloaded. Tap to remove."
        case .failed: return "Download failed. Tap to retry."
        }
    }
}

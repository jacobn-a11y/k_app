import SwiftUI

struct DownloadsSettingsView: View {
    let downloadManager: MediaDownloadManager

    @State private var showDeleteAllConfirmation = false

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Storage Used", systemImage: "internaldrive")
                    Spacer()
                    Text(downloadManager.formattedTotalSize)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Storage used: \(downloadManager.formattedTotalSize)")

                HStack {
                    Label("Downloaded Items", systemImage: "arrow.down.circle.fill")
                    Spacer()
                    Text("\(downloadManager.downloadedMedia.count)")
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }

            if !downloadManager.downloadedMedia.isEmpty {
                Section("Downloaded Media") {
                    ForEach(downloadManager.downloadedMedia) { media in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(media.title)
                                    .font(.subheadline)
                                Text(ByteCountFormatter.string(
                                    fromByteCount: media.fileSize,
                                    countStyle: .file
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                downloadManager.removeDownload(mediaId: media.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                            .accessibleButton("Delete \(media.title)")
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteAllConfirmation = true
                    } label: {
                        Label("Remove All Downloads", systemImage: "trash.fill")
                    }
                    .accessibilityHint("Removes all downloaded media to free up storage")
                }
            } else {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No Downloads")
                            .font(.headline)
                        Text("Downloaded media will appear here for offline use.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Downloads")
        .confirmationDialog(
            "Remove All Downloads?",
            isPresented: $showDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove All", role: .destructive) {
                downloadManager.removeAllDownloads()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will free up \(downloadManager.formattedTotalSize) of storage. You can re-download media later when online.")
        }
    }
}

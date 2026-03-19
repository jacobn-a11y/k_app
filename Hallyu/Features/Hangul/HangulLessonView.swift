import SwiftUI
import SwiftData

struct HangulLessonView: View {
    @State private var viewModel: HangulLessonViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var didPersistReviewItems = false

    init(groupIndex: Int, services: ServiceContainer) {
        _viewModel = State(initialValue: HangulLessonViewModel(
            groupIndex: groupIndex,
            claudeService: services.claude,
            speechService: services.speechRecognition,
            audioService: services.audio
        ))
    }

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLessonComplete {
                    lessonCompleteView
                } else if let jamo = viewModel.currentJamo {
                    VStack(spacing: 0) {
                        // Progress bar
                        ProgressView(value: viewModel.progress)
                            .tint(.accentColor)
                            .padding(.horizontal)

                        // Jamo counter
                        Text("\(viewModel.completedJamoCount + 1) of \(viewModel.totalJamoCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)

                        JamoDetailView(
                            jamo: jamo,
                            step: viewModel.currentStep,
                            pronunciationFeedback: viewModel.pronunciationFeedback,
                            pronunciationScore: viewModel.pronunciationScore,
                            recognitionResult: viewModel.recognitionResult,
                            isRecording: viewModel.isRecording,
                            onAdvance: { viewModel.advanceStep() },
                            onTrace: { score in viewModel.recordTraceScore(score) },
                            onStartRecording: {
                                Task { try? await viewModel.startRecording() }
                            },
                            onStopRecording: {
                                Task { try? await viewModel.stopRecordingAndRecognize() }
                            },
                            onPlayPronunciation: {
                                Task { try? await viewModel.playPronunciation() }
                            }
                        )
                    }
                }
            }
            .navigationTitle(viewModel.group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var lessonCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "star.fill")
                .scaledFont(size: 60)
                .foregroundStyle(.yellow)

            Text("Lesson Complete!")
                .font(.largeTitle.bold())

            Text(viewModel.group.name)
                .font(.title2)
                .foregroundStyle(.secondary)

            // Score display
            VStack(spacing: 12) {
                Text("Score: \(Int(viewModel.overallScore * 100))%")
                    .font(.title)
                    .fontWeight(.bold)

                ForEach(Array(viewModel.scores.values.sorted { $0.jamoId < $1.jamoId }), id: \.jamoId) { score in
                    HStack {
                        Text(score.jamoId)
                            .font(.title2)
                            .frame(width: 40)

                        ProgressView(value: score.combined)
                            .tint(score.combined > 0.7 ? .green : .orange)

                        Text("\(Int(score.combined * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 40)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            Button(action: { dismiss() }) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            persistReviewItemsIfNeeded()
        }
    }

    private func persistReviewItemsIfNeeded() {
        guard !didPersistReviewItems else { return }
        didPersistReviewItems = true

        let userId = appState.currentUserId ?? UUID()
        if appState.currentUserId == nil {
            appState.currentUserId = userId
        }

        let reviewItems = viewModel.createReviewItems(userId: userId)
        let existing = (try? modelContext.fetch(FetchDescriptor<ReviewItem>())) ?? []
        let existingKeys = Set(existing.map { "\($0.userId.uuidString)_\($0.itemType)_\($0.itemId.uuidString)" })

        for item in reviewItems {
            let key = "\(item.userId.uuidString)_\(item.itemType)_\(item.itemId.uuidString)"
            if !existingKeys.contains(key) {
                modelContext.insert(item)
            }
        }

        if let profile = (try? modelContext.fetch(FetchDescriptor<LearnerProfile>()))?.first(where: { $0.userId == userId }) {
            profile.hangulCompleted = true
            profile.updatedAt = Date()
        }

        try? modelContext.save()
    }
}

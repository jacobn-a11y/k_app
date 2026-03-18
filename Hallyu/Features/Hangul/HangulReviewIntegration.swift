import Foundation

/// Handles creating and managing SRS review items for Hangul learning.
enum HangulReviewIntegration {

    enum ReviewMode: String, CaseIterable {
        case recognition // see block → say sound
        case production  // hear sound → construct block
    }

    /// Create review items for a completed jamo lesson.
    static func createReviewItems(
        userId: UUID,
        completedJamoIds: [String],
        mode: ReviewMode = .recognition
    ) -> [ReviewItem] {
        completedJamoIds.map { jamoId in
            ReviewItem(
                userId: userId,
                itemType: "hangul_\(mode.rawValue)",
                itemId: deterministicUUID(for: "\(userId)_\(jamoId)_\(mode.rawValue)"),
                halfLifeDays: 1.0,
                nextReviewAt: Date().addingTimeInterval(86400) // first review in 24h
            )
        }
    }

    /// Create review items for completed syllable blocks.
    static func createSyllableBlockReviewItems(
        userId: UUID,
        syllables: [Character]
    ) -> [ReviewItem] {
        syllables.map { syllable in
            ReviewItem(
                userId: userId,
                itemType: "hangul_syllable",
                itemId: deterministicUUID(for: "\(userId)_\(syllable)"),
                halfLifeDays: 1.0,
                nextReviewAt: Date().addingTimeInterval(86400)
            )
        }
    }

    /// Generate a deterministic UUID from a string (for stable item IDs).
    private static func deterministicUUID(for input: String) -> UUID {
        var hash: UInt64 = 5381
        for byte in input.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        let bytes = withUnsafeBytes(of: hash) { Array($0) }
        var uuidBytes: [UInt8] = Array(repeating: 0, count: 16)
        for i in 0..<min(bytes.count, 8) {
            uuidBytes[i] = bytes[i]
            uuidBytes[i + 8] = bytes[i] ^ 0xFF
        }
        // Set version 4 and variant bits
        uuidBytes[6] = (uuidBytes[6] & 0x0F) | 0x40
        uuidBytes[8] = (uuidBytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        ))
    }
}

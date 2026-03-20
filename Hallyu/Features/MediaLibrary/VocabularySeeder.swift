import Foundation
import SwiftData

/// Seeds core VocabularyItem records for development/testing.
/// Words are sourced from KoreanTextAnalyzer.frequencyList and tagged with media domains
/// to enable topic-aware lesson matching.
enum VocabularySeeder {

    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<VocabularyItem>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for item in allItems {
            modelContext.insert(item)
        }
        try? modelContext.save()
    }

    static let allItems: [VocabularyItem] = entries.map { entry in
        VocabularyItem(
            korean: entry.korean,
            romanization: entry.romanization,
            english: entry.english,
            partOfSpeech: entry.partOfSpeech,
            cefrLevel: entry.cefrLevel,
            frequencyRank: entry.rank,
            mediaDomains: entry.domains
        )
    }

    // MARK: - Data

    private struct Entry {
        let korean: String
        let romanization: String
        let english: String
        let partOfSpeech: String
        let rank: Int
        let cefrLevel: String
        let domains: [String]
    }

    // Frequency rank → CEFR: 1-100 = A1, 101-200 = A2, 201-400 = B1
    private static let entries: [Entry] = [
        // Food & Dining
        Entry(korean: "먹다", romanization: "meokda", english: "to eat", partOfSpeech: "verb", rank: 51, cefrLevel: "A1", domains: ["food"]),
        Entry(korean: "마시다", romanization: "masida", english: "to drink", partOfSpeech: "verb", rank: 52, cefrLevel: "A1", domains: ["food", "cafe"]),
        Entry(korean: "밥", romanization: "bap", english: "rice/meal", partOfSpeech: "noun", rank: 77, cefrLevel: "A1", domains: ["food"]),
        Entry(korean: "물", romanization: "mul", english: "water", partOfSpeech: "noun", rank: 76, cefrLevel: "A1", domains: ["food"]),
        Entry(korean: "음식", romanization: "eumsik", english: "food", partOfSpeech: "noun", rank: 118, cefrLevel: "A2", domains: ["food"]),
        Entry(korean: "김치", romanization: "gimchi", english: "kimchi", partOfSpeech: "noun", rank: 150, cefrLevel: "A2", domains: ["food", "culture"]),
        Entry(korean: "라면", romanization: "ramyeon", english: "ramyeon", partOfSpeech: "noun", rank: 160, cefrLevel: "A2", domains: ["food"]),
        Entry(korean: "커피", romanization: "keopi", english: "coffee", partOfSpeech: "noun", rank: 169, cefrLevel: "A2", domains: ["cafe", "food"]),
        Entry(korean: "식당", romanization: "sikdang", english: "restaurant", partOfSpeech: "noun", rank: 168, cefrLevel: "A2", domains: ["food"]),
        Entry(korean: "맛있다", romanization: "masitda", english: "delicious", partOfSpeech: "adjective", rank: 120, cefrLevel: "A2", domains: ["food"]),
        Entry(korean: "요리사", romanization: "yorisa", english: "chef", partOfSpeech: "noun", rank: 286, cefrLevel: "B1", domains: ["food", "workplace"]),
        Entry(korean: "주문하다", romanization: "jumunhada", english: "to order", partOfSpeech: "verb", rank: 278, cefrLevel: "B1", domains: ["food", "shopping"]),

        // Shopping & Market
        Entry(korean: "사다", romanization: "sada", english: "to buy", partOfSpeech: "verb", rank: 110, cefrLevel: "A2", domains: ["shopping"]),
        Entry(korean: "돈", romanization: "don", english: "money", partOfSpeech: "noun", rank: 102, cefrLevel: "A2", domains: ["shopping"]),
        Entry(korean: "가게", romanization: "gage", english: "shop/store", partOfSpeech: "noun", rank: 171, cefrLevel: "A2", domains: ["shopping", "market"]),
        Entry(korean: "마트", romanization: "mateu", english: "mart/supermarket", partOfSpeech: "noun", rank: 170, cefrLevel: "A2", domains: ["shopping", "market"]),
        Entry(korean: "비싸다", romanization: "bissada", english: "expensive", partOfSpeech: "adjective", rank: 200, cefrLevel: "A2", domains: ["shopping"]),
        Entry(korean: "싸다", romanization: "ssada", english: "cheap", partOfSpeech: "adjective", rank: 201, cefrLevel: "B1", domains: ["shopping", "market"]),
        Entry(korean: "원", romanization: "won", english: "won (currency)", partOfSpeech: "noun", rank: 209, cefrLevel: "B1", domains: ["shopping"]),
        Entry(korean: "계산하다", romanization: "gyesanhada", english: "to pay/calculate", partOfSpeech: "verb", rank: 279, cefrLevel: "B1", domains: ["shopping"]),

        // Greetings & Social
        Entry(korean: "안녕하세요", romanization: "annyeonghaseyo", english: "hello", partOfSpeech: "expression", rank: 401, cefrLevel: "A1", domains: ["greeting"]),
        Entry(korean: "감사합니다", romanization: "gamsahamnida", english: "thank you", partOfSpeech: "expression", rank: 402, cefrLevel: "A1", domains: ["greeting"]),
        Entry(korean: "죄송합니다", romanization: "joesonghamnida", english: "I'm sorry", partOfSpeech: "expression", rank: 403, cefrLevel: "A1", domains: ["greeting"]),
        Entry(korean: "만나다", romanization: "mannada", english: "to meet", partOfSpeech: "verb", rank: 59, cefrLevel: "A1", domains: ["greeting", "romance"]),

        // Family
        Entry(korean: "가족", romanization: "gajok", english: "family", partOfSpeech: "noun", rank: 63, cefrLevel: "A1", domains: ["family"]),
        Entry(korean: "엄마", romanization: "eomma", english: "mom", partOfSpeech: "noun", rank: 64, cefrLevel: "A1", domains: ["family"]),
        Entry(korean: "아빠", romanization: "appa", english: "dad", partOfSpeech: "noun", rank: 65, cefrLevel: "A1", domains: ["family"]),
        Entry(korean: "형", romanization: "hyeong", english: "older brother (male)", partOfSpeech: "noun", rank: 66, cefrLevel: "A1", domains: ["family"]),
        Entry(korean: "동생", romanization: "dongsaeng", english: "younger sibling", partOfSpeech: "noun", rank: 68, cefrLevel: "A1", domains: ["family"]),
        Entry(korean: "부모님", romanization: "bumonim", english: "parents", partOfSpeech: "noun", rank: 290, cefrLevel: "B1", domains: ["family"]),
        Entry(korean: "할머니", romanization: "halmeoni", english: "grandmother", partOfSpeech: "noun", rank: 291, cefrLevel: "B1", domains: ["family"]),
        Entry(korean: "아들", romanization: "adeul", english: "son", partOfSpeech: "noun", rank: 293, cefrLevel: "B1", domains: ["family"]),
        Entry(korean: "딸", romanization: "ttal", english: "daughter", partOfSpeech: "noun", rank: 294, cefrLevel: "B1", domains: ["family"]),

        // School & Education
        Entry(korean: "학교", romanization: "hakgyo", english: "school", partOfSpeech: "noun", rank: 71, cefrLevel: "A1", domains: ["school", "education"]),
        Entry(korean: "학생", romanization: "haksaeng", english: "student", partOfSpeech: "noun", rank: 70, cefrLevel: "A1", domains: ["school", "education"]),
        Entry(korean: "선생님", romanization: "seonsaengnim", english: "teacher", partOfSpeech: "noun", rank: 69, cefrLevel: "A1", domains: ["school", "education"]),
        Entry(korean: "공부", romanization: "gongbu", english: "study", partOfSpeech: "noun", rank: 136, cefrLevel: "A2", domains: ["school", "education"]),
        Entry(korean: "시험", romanization: "siheom", english: "test/exam", partOfSpeech: "noun", rank: 138, cefrLevel: "A2", domains: ["school", "education"]),
        Entry(korean: "숙제", romanization: "sukje", english: "homework", partOfSpeech: "noun", rank: 137, cefrLevel: "A2", domains: ["school"]),
        Entry(korean: "배우다", romanization: "baeuda", english: "to learn", partOfSpeech: "verb", rank: 108, cefrLevel: "A2", domains: ["school", "education"]),
        Entry(korean: "교육", romanization: "gyoyuk", english: "education", partOfSpeech: "noun", rank: 341, cefrLevel: "B1", domains: ["education"]),

        // Workplace
        Entry(korean: "회사", romanization: "hoesa", english: "company", partOfSpeech: "noun", rank: 72, cefrLevel: "A1", domains: ["workplace"]),
        Entry(korean: "일", romanization: "il", english: "work", partOfSpeech: "noun", rank: 103, cefrLevel: "A2", domains: ["workplace"]),
        Entry(korean: "직업", romanization: "jigeop", english: "job/occupation", partOfSpeech: "noun", rank: 281, cefrLevel: "B1", domains: ["workplace"]),
        Entry(korean: "회사원", romanization: "hoesawon", english: "office worker", partOfSpeech: "noun", rank: 288, cefrLevel: "B1", domains: ["workplace"]),

        // Travel & Transportation
        Entry(korean: "여행", romanization: "yeohaeng", english: "travel", partOfSpeech: "noun", rank: 117, cefrLevel: "A2", domains: ["travel"]),
        Entry(korean: "버스", romanization: "beoseu", english: "bus", partOfSpeech: "noun", rank: 162, cefrLevel: "A2", domains: ["travel", "transportation"]),
        Entry(korean: "지하철", romanization: "jihacheol", english: "subway", partOfSpeech: "noun", rank: 163, cefrLevel: "A2", domains: ["travel", "transportation"]),
        Entry(korean: "택시", romanization: "taeksi", english: "taxi", partOfSpeech: "noun", rank: 164, cefrLevel: "A2", domains: ["travel", "transportation"]),
        Entry(korean: "비행기", romanization: "bihaenggi", english: "airplane", partOfSpeech: "noun", rank: 165, cefrLevel: "A2", domains: ["travel"]),
        Entry(korean: "역", romanization: "yeok", english: "station", partOfSpeech: "noun", rank: 173, cefrLevel: "A2", domains: ["travel", "transportation"]),

        // Medical & Health
        Entry(korean: "병원", romanization: "byeongwon", english: "hospital", partOfSpeech: "noun", rank: 166, cefrLevel: "A2", domains: ["medical", "health"]),
        Entry(korean: "의사", romanization: "uisa", english: "doctor", partOfSpeech: "noun", rank: 282, cefrLevel: "B1", domains: ["medical", "workplace"]),
        Entry(korean: "아프다", romanization: "apeuda", english: "to be sick/hurt", partOfSpeech: "adjective", rank: 312, cefrLevel: "B1", domains: ["medical", "health"]),
        Entry(korean: "약", romanization: "yak", english: "medicine", partOfSpeech: "noun", rank: 313, cefrLevel: "B1", domains: ["medical", "health"]),
        Entry(korean: "건강", romanization: "geongang", english: "health", partOfSpeech: "noun", rank: 311, cefrLevel: "B1", domains: ["health"]),

        // Romance & Emotion
        Entry(korean: "사랑", romanization: "sarang", english: "love", partOfSpeech: "noun", rank: 61, cefrLevel: "A1", domains: ["romance", "emotional"]),
        Entry(korean: "좋아하다", romanization: "joahada", english: "to like", partOfSpeech: "verb", rank: 24, cefrLevel: "A1", domains: ["romance"]),
        Entry(korean: "행복", romanization: "haengbok", english: "happiness", partOfSpeech: "noun", rank: 128, cefrLevel: "A2", domains: ["emotional"]),
        Entry(korean: "슬프다", romanization: "seulpeuda", english: "to be sad", partOfSpeech: "adjective", rank: 129, cefrLevel: "A2", domains: ["emotional"]),
        Entry(korean: "결혼", romanization: "gyeolhon", english: "marriage", partOfSpeech: "noun", rank: 115, cefrLevel: "A2", domains: ["romance", "family"]),

        // Culture & Entertainment
        Entry(korean: "노래", romanization: "norae", english: "song", partOfSpeech: "noun", rank: 119, cefrLevel: "A2", domains: ["music", "culture"]),
        Entry(korean: "영화", romanization: "yeonghwa", english: "movie", partOfSpeech: "noun", rank: 120, cefrLevel: "A2", domains: ["culture"]),
        Entry(korean: "드라마", romanization: "deurama", english: "drama", partOfSpeech: "noun", rank: 121, cefrLevel: "A2", domains: ["culture"]),
        Entry(korean: "음악", romanization: "eumak", english: "music", partOfSpeech: "noun", rank: 346, cefrLevel: "B1", domains: ["music", "culture"]),
        Entry(korean: "문화", romanization: "munhwa", english: "culture", partOfSpeech: "noun", rank: 335, cefrLevel: "B1", domains: ["culture"]),
        Entry(korean: "전통", romanization: "jeontong", english: "tradition", partOfSpeech: "noun", rank: 337, cefrLevel: "B1", domains: ["culture"]),
        Entry(korean: "춤", romanization: "chum", english: "dance", partOfSpeech: "noun", rank: 348, cefrLevel: "B1", domains: ["music", "culture"]),

        // Weather & Nature
        Entry(korean: "날씨", romanization: "nalssi", english: "weather", partOfSpeech: "noun", rank: 83, cefrLevel: "A1", domains: ["weather"]),
        Entry(korean: "비", romanization: "bi", english: "rain", partOfSpeech: "noun", rank: 151, cefrLevel: "A2", domains: ["weather"]),
        Entry(korean: "눈", romanization: "nun", english: "snow/eyes", partOfSpeech: "noun", rank: 152, cefrLevel: "A2", domains: ["weather"]),
        Entry(korean: "바람", romanization: "baram", english: "wind", partOfSpeech: "noun", rank: 153, cefrLevel: "A2", domains: ["weather"]),
        Entry(korean: "봄", romanization: "bom", english: "spring", partOfSpeech: "noun", rank: 147, cefrLevel: "A2", domains: ["weather", "culture"]),
        Entry(korean: "하늘", romanization: "haneul", english: "sky", partOfSpeech: "noun", rank: 154, cefrLevel: "A2", domains: ["weather"]),
        Entry(korean: "바다", romanization: "bada", english: "sea/ocean", partOfSpeech: "noun", rank: 155, cefrLevel: "A2", domains: ["travel"]),

        // Daily Life
        Entry(korean: "집", romanization: "jip", english: "house/home", partOfSpeech: "noun", rank: 73, cefrLevel: "A1", domains: ["daily-life"]),
        Entry(korean: "오늘", romanization: "oneul", english: "today", partOfSpeech: "noun", rank: 78, cefrLevel: "A1", domains: ["daily-life"]),
        Entry(korean: "시간", romanization: "sigan", english: "time", partOfSpeech: "noun", rank: 82, cefrLevel: "A1", domains: ["daily-life"]),
        Entry(korean: "친구", romanization: "chingu", english: "friend", partOfSpeech: "noun", rank: 62, cefrLevel: "A1", domains: ["friends"]),
        Entry(korean: "사람", romanization: "saram", english: "person/people", partOfSpeech: "noun", rank: 17, cefrLevel: "A1", domains: ["daily-life"]),
        Entry(korean: "운동", romanization: "undong", english: "exercise", partOfSpeech: "noun", rank: 135, cefrLevel: "A2", domains: ["health", "sports"]),
        Entry(korean: "환경", romanization: "hwangyeong", english: "environment", partOfSpeech: "noun", rank: 342, cefrLevel: "B1", domains: ["environment"]),
        Entry(korean: "기술", romanization: "gisul", english: "technology", partOfSpeech: "noun", rank: 344, cefrLevel: "B1", domains: ["technology"]),
        Entry(korean: "경제", romanization: "gyeongje", english: "economy", partOfSpeech: "noun", rank: 339, cefrLevel: "B1", domains: ["economy"]),
    ]
}

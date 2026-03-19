import Foundation
import SwiftData

enum MediaContentSeeder {

    /// Seed placeholder media content for development/testing.
    /// Real licensed content is a business operation — these are schema-correct placeholders.
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<MediaContent>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let allContent = dramaClips + webtoonExcerpts + newsArticles + shortVideoClips + musicClips
        for content in allContent {
            modelContext.insert(content)
        }
        try? modelContext.save()
    }

    /// Generate all placeholder content for testing without SwiftData
    static func allPlaceholderContent() -> [MediaContent] {
        dramaClips + webtoonExcerpts + newsArticles + shortVideoClips + musicClips
    }

    // MARK: - K-Drama Clips (50)

    static let dramaClips: [MediaContent] = {
        let dramas: [(String, String, String, Double, String, Int, String, String, [MediaContent.TranscriptSegment], [String])] = [
            ("First Meeting", "Encounter", "A1", 0.25, "Two strangers meet at a convenience store", 150,
             "안녕하세요. 혹시 이거 어디서 사요?",
             "Bowing when meeting strangers is common Korean etiquette",
             [MediaContent.TranscriptSegment(startMs: 0, endMs: 3000, textKr: "안녕하세요", textEn: "Hello"),
              MediaContent.TranscriptSegment(startMs: 3000, endMs: 8000, textKr: "혹시 이거 어디서 사요?", textEn: "Where can I buy this?"),
              MediaContent.TranscriptSegment(startMs: 8000, endMs: 12000, textKr: "여기 있어요", textEn: "It's right here")],
             ["greeting", "shopping", "beginner"]),

            ("Coffee Date", "Goblin", "A1", 0.3, "Friends ordering coffee at a cafe", 180,
             "커피 주세요. 아메리카노 하나요. 감사합니다.",
             "Korean cafe culture: ordering is often done at the counter",
             [MediaContent.TranscriptSegment(startMs: 0, endMs: 4000, textKr: "커피 주세요", textEn: "Coffee please"),
              MediaContent.TranscriptSegment(startMs: 4000, endMs: 8000, textKr: "아메리카노 하나요", textEn: "One Americano"),
              MediaContent.TranscriptSegment(startMs: 8000, endMs: 11000, textKr: "감사합니다", textEn: "Thank you")],
             ["cafe", "ordering", "beginner"]),

            ("Family Dinner", "Reply 1988", "A2", 0.4, "Family gathering around the dinner table", 240,
             "밥 먹었어? 오늘 날씨가 좋아서 기분이 좋아요.",
             "Asking 'have you eaten?' is a common greeting showing care",
             [MediaContent.TranscriptSegment(startMs: 0, endMs: 5000, textKr: "밥 먹었어?", textEn: "Have you eaten?"),
              MediaContent.TranscriptSegment(startMs: 5000, endMs: 10000, textKr: "오늘 날씨가 좋아서 기분이 좋아요", textEn: "The weather is nice today so I feel good")],
             ["family", "food", "greetings"]),

            ("Office Scene", "Misaeng", "A2", 0.45, "New employee's first day at work", 200,
             "안녕하세요. 오늘부터 여기서 일하게 되었습니다. 잘 부탁드립니다.",
             "Korean workplace hierarchy: using formal speech with seniors",
             [MediaContent.TranscriptSegment(startMs: 0, endMs: 5000, textKr: "안녕하세요", textEn: "Hello"),
              MediaContent.TranscriptSegment(startMs: 5000, endMs: 12000, textKr: "오늘부터 여기서 일하게 되었습니다", textEn: "I will be working here starting today"),
              MediaContent.TranscriptSegment(startMs: 12000, endMs: 16000, textKr: "잘 부탁드립니다", textEn: "Please take care of me")],
             ["workplace", "formal", "introduction"]),

            ("Rooftop Confession", "My Love from the Star", "B1", 0.55, "Emotional confession scene on a rooftop", 300,
             "나는 당신을 처음 만난 그날부터 좋아했어요. 이 마음을 더 이상 숨길 수 없어요.",
             "Confessions in Korean dramas often happen in scenic outdoor locations",
             [MediaContent.TranscriptSegment(startMs: 0, endMs: 8000, textKr: "나는 당신을 처음 만난 그날부터 좋아했어요", textEn: "I've liked you since the day I first met you"),
              MediaContent.TranscriptSegment(startMs: 8000, endMs: 15000, textKr: "이 마음을 더 이상 숨길 수 없어요", textEn: "I can't hide these feelings any longer")],
             ["romance", "confession", "emotional"]),

            ("Hospital Drama", "Hospital Playlist", "B1", 0.6, "Doctors discussing a patient case", 270,
             "환자의 상태가 좋지 않습니다. 수술이 필요할 것 같습니다.",
             "Medical dramas reflect Korea's advanced healthcare system",
             [MediaContent.TranscriptSegment(startMs: 0, endMs: 6000, textKr: "환자의 상태가 좋지 않습니다", textEn: "The patient's condition is not good"),
              MediaContent.TranscriptSegment(startMs: 6000, endMs: 12000, textKr: "수술이 필요할 것 같습니다", textEn: "I think surgery will be necessary")],
             ["medical", "formal", "professional"]),

            ("School Life", "True Beauty", "A1", 0.2, "Students chatting in a classroom", 160,
             "오늘 시험 공부했어? 나는 아직 안 했어.",
             "Korean school life: studying is a central activity for students",
             [MediaContent.TranscriptSegment(startMs: 0, endMs: 5000, textKr: "오늘 시험 공부했어?", textEn: "Did you study for today's test?"),
              MediaContent.TranscriptSegment(startMs: 5000, endMs: 9000, textKr: "나는 아직 안 했어", textEn: "I haven't yet")],
             ["school", "casual", "friends"]),

            ("Market Shopping", "Weightlifting Fairy", "A1", 0.28, "Shopping at a traditional market", 190,
             "이거 얼마예요? 너무 비싸요. 좀 깎아 주세요.",
             "Bargaining is common in traditional Korean markets",
             [MediaContent.TranscriptSegment(startMs: 0, endMs: 4000, textKr: "이거 얼마예요?", textEn: "How much is this?"),
              MediaContent.TranscriptSegment(startMs: 4000, endMs: 7000, textKr: "너무 비싸요", textEn: "It's too expensive"),
              MediaContent.TranscriptSegment(startMs: 7000, endMs: 11000, textKr: "좀 깎아 주세요", textEn: "Please give me a discount")],
             ["shopping", "market", "bargaining"]),

            ("Train Station", "Crash Landing on You", "A2", 0.38, "Farewell scene at a train station", 220,
             "잘 가요. 다음에 또 만나요. 연락할게요.",
             "Train stations are common farewell scenes in Korean dramas",
             [MediaContent.TranscriptSegment(startMs: 0, endMs: 4000, textKr: "잘 가요", textEn: "Goodbye"),
              MediaContent.TranscriptSegment(startMs: 4000, endMs: 8000, textKr: "다음에 또 만나요", textEn: "Let's meet again next time"),
              MediaContent.TranscriptSegment(startMs: 8000, endMs: 12000, textKr: "연락할게요", textEn: "I'll contact you")],
             ["farewell", "travel", "emotional"]),

            ("Late Night Snack", "Itaewon Class", "A2", 0.35, "Friends eating ramyeon late at night", 200,
             "배고프다. 라면 먹을래? 맛있겠다!",
             "Late-night ramyeon is a beloved Korean comfort food tradition",
             [MediaContent.TranscriptSegment(startMs: 0, endMs: 3000, textKr: "배고프다", textEn: "I'm hungry"),
              MediaContent.TranscriptSegment(startMs: 3000, endMs: 7000, textKr: "라면 먹을래?", textEn: "Want to eat ramyeon?"),
              MediaContent.TranscriptSegment(startMs: 7000, endMs: 10000, textKr: "맛있겠다!", textEn: "That looks delicious!")],
             ["food", "casual", "friends"]),
        ]

        // Generate 50 drama clips by repeating variations
        var clips: [MediaContent] = []
        let variations = ["Part 1", "Part 2", "Part 3", "Part 4", "Part 5"]
        for (index, drama) in dramas.enumerated() {
            for (varIndex, variation) in variations.enumerated() {
                let clipIndex = index * variations.count + varIndex
                guard clipIndex < 50 else { break }
                clips.append(MediaContent(
                    title: "\(drama.0) - \(variation)",
                    contentType: "drama",
                    source: drama.1,
                    difficultyScore: min(drama.3 + Double(varIndex) * 0.02, 0.95),
                    cefrLevel: drama.2,
                    durationSeconds: drama.5 + varIndex * 30,
                    transcriptKr: drama.6,
                    transcriptSegments: drama.8,
                    mediaUrl: "placeholder://drama/\(clipIndex)",
                    culturalNotes: drama.7,
                    tags: drama.9
                ))
            }
        }
        return clips
    }()

    // MARK: - Webtoon Excerpts (30)

    static let webtoonExcerpts: [MediaContent] = {
        let webtoons: [(String, String, String, Double, String, [String])] = [
            ("Tower of God Ch.1", "Tower of God", "A1", 0.2, "별을 보고 싶어. 하늘이 보고 싶어. 밤이 보고 싶어.", ["fantasy", "adventure"]),
            ("Solo Leveling Ch.1", "Solo Leveling", "A2", 0.4, "나는 세계 최약체 사냥꾼이다. 하지만 오늘부터 변한다.", ["action", "fantasy"]),
            ("True Beauty Ch.1", "True Beauty", "A1", 0.25, "학교에서 인기가 없었어요. 하지만 화장을 하면 달라져요.", ["romance", "school"]),
            ("Noblesse Ch.1", "Noblesse", "B1", 0.5, "오랜 잠에서 깨어났다. 세상이 많이 변했구나.", ["action", "supernatural"]),
            ("Sweet Home Ch.1", "Sweet Home", "A2", 0.45, "이 아파트에서 무서운 일이 일어나고 있어요.", ["horror", "thriller"]),
            ("Cheese in the Trap", "Cheese in the Trap", "A2", 0.38, "그 선배는 항상 웃지만 뭔가 이상해요.", ["romance", "mystery"]),
            ("Lookism Ch.1", "Lookism", "A1", 0.3, "나는 못생겼어요. 친구가 없어요. 하지만 어느 날 변했어요.", ["drama", "school"]),
            ("Omniscient Reader", "Omniscient Reader", "B1", 0.55, "내가 읽던 소설이 현실이 되었다.", ["fantasy", "isekai"]),
            ("Wind Breaker", "Wind Breaker", "A2", 0.42, "자전거를 타면 자유로워요. 바람이 좋아요.", ["sports", "cycling"]),
            ("The God of High School", "God of High School", "B1", 0.52, "최강의 고등학생을 가리는 대회가 시작된다.", ["action", "martial-arts"]),
        ]

        var excerpts: [MediaContent] = []
        for (index, webtoon) in webtoons.enumerated() {
            for chapter in 1...3 {
                let excerptIndex = index * 3 + chapter - 1
                guard excerptIndex < 30 else { break }
                excerpts.append(MediaContent(
                    title: "\(webtoon.0) Ep.\(chapter)",
                    contentType: "webtoon",
                    source: webtoon.1,
                    difficultyScore: min(webtoon.3 + Double(chapter) * 0.03, 0.9),
                    cefrLevel: webtoon.2,
                    durationSeconds: 0,
                    transcriptKr: webtoon.4,
                    mediaUrl: "placeholder://webtoon/\(excerptIndex)",
                    tags: webtoon.5
                ))
            }
        }
        return excerpts
    }()

    // MARK: - News Articles (20)

    static let newsArticles: [MediaContent] = {
        let articles: [(String, String, Double, String, String, [String])] = [
            ("오늘의 날씨", "KBS News", 0.25, "A1",
             "오늘 서울의 날씨는 맑겠습니다. 기온은 20도입니다. 내일은 비가 올 것 같습니다.",
             ["weather", "daily"]),
            ("한국 음식이 세계에서 인기", "MBC News", 0.35, "A2",
             "한국 음식이 전 세계에서 인기를 얻고 있습니다. 특히 김치와 비빔밥이 유명합니다.",
             ["food", "culture", "global"]),
            ("새로운 지하철 노선 개통", "SBS News", 0.4, "A2",
             "서울에 새로운 지하철 노선이 개통되었습니다. 많은 시민들이 편리하게 이용하고 있습니다.",
             ["transportation", "city"]),
            ("한류 문화의 영향", "Yonhap", 0.55, "B1",
             "한류 문화가 세계적으로 큰 영향을 미치고 있습니다. 한국어를 배우는 사람들이 크게 증가하고 있습니다.",
             ["hallyu", "culture", "language"]),
            ("기술 발전과 일상생활", "Korea Herald", 0.6, "B1",
             "기술의 발전이 우리의 일상생활을 크게 변화시키고 있습니다. 특히 인공지능 기술이 빠르게 발전하고 있습니다.",
             ["technology", "AI", "daily-life"]),
            ("한국 교육 시스템", "JoongAng", 0.5, "B1",
             "한국의 교육 시스템은 세계적으로 높은 수준입니다. 하지만 학생들의 스트레스가 문제입니다.",
             ["education", "society"]),
            ("봄 축제 소식", "KBS News", 0.3, "A1",
             "봄이 왔습니다. 전국에서 꽃 축제가 열리고 있습니다. 많은 사람들이 즐기고 있습니다.",
             ["festival", "spring", "culture"]),
            ("한국 경제 뉴스", "Maeil Business", 0.65, "B2",
             "한국 경제가 안정적으로 성장하고 있습니다. 수출이 증가하면서 긍정적인 전망이 나오고 있습니다.",
             ["economy", "business"]),
            ("건강한 생활습관", "Health News", 0.35, "A2",
             "건강하게 살려면 운동을 해야 합니다. 매일 30분 걷는 것이 좋습니다.",
             ["health", "lifestyle"]),
            ("환경 보호 캠페인", "Green Korea", 0.5, "B1",
             "환경 보호를 위한 캠페인이 전국적으로 진행되고 있습니다. 많은 시민들이 참여하고 있습니다.",
             ["environment", "campaign"]),
        ]

        var newsContent: [MediaContent] = []
        for (index, article) in articles.enumerated() {
            newsContent.append(MediaContent(
                title: article.0,
                contentType: "news",
                source: article.1,
                difficultyScore: article.2,
                cefrLevel: article.3,
                durationSeconds: 0,
                transcriptKr: article.4,
                tags: article.5
            ))
            // Create a follow-up article for some
            if index < 10 {
                newsContent.append(MediaContent(
                    title: "\(article.0) (후속 보도)",
                    contentType: "news",
                    source: article.1,
                    difficultyScore: min(article.2 + 0.05, 0.9),
                    cefrLevel: article.3,
                    durationSeconds: 0,
                    transcriptKr: article.4,
                    tags: article.5
                ))
            }
        }
        return Array(newsContent.prefix(20))
    }()

    // MARK: - Short Video Clips

    static let shortVideoClips: [MediaContent] = {
        (0..<10).map { i in
            let titles = [
                "Korean Street Food Tour", "Seoul Night Walk", "Hanbok Experience",
                "K-Pop Dance Tutorial", "Korean Skincare Routine", "Temple Stay Vlog",
                "Korean Cooking: Kimchi", "Cafe Hopping in Gangnam", "Subway Guide Seoul",
                "Korean Market Tour"
            ]
            let transcripts = [
                "오늘은 길거리 음식을 먹어볼 거예요. 떡볶이가 맛있어 보여요.",
                "서울의 밤은 정말 아름답습니다. 야경이 멋져요.",
                "한복을 입어봤어요. 너무 예뻐요! 전통 문화를 체험할 수 있어요.",
                "오늘은 케이팝 댄스를 배워볼 거예요. 따라해 보세요!",
                "한국 스킨케어 루틴을 소개합니다. 피부가 좋아져요.",
                "절에서 하루를 보냈어요. 조용하고 평화로웠어요.",
                "오늘은 김치를 만들어 볼 거예요. 재료를 준비하세요.",
                "강남에서 카페를 찾아다녔어요. 커피가 정말 맛있었어요.",
                "서울 지하철 타는 방법을 알려줄게요. 쉬워요!",
                "전통 시장에서 쇼핑했어요. 물건이 많고 싸요."
            ]
            let levels = ["A1", "A1", "A2", "A2", "A2", "B1", "A1", "A2", "A1", "A1"]
            let scores = [0.2, 0.25, 0.35, 0.4, 0.38, 0.5, 0.22, 0.36, 0.2, 0.28]

            return MediaContent(
                title: titles[i],
                contentType: "short_video",
                source: "YouTube Korea",
                difficultyScore: scores[i],
                cefrLevel: levels[i],
                durationSeconds: 60 + i * 15,
                transcriptKr: transcripts[i],
                transcriptSegments: [
                    MediaContent.TranscriptSegment(startMs: 0, endMs: 5000, textKr: transcripts[i], textEn: "")
                ],
                tags: ["vlog", "culture"]
            )
        }
    }()

    // MARK: - Music Clips

    static let musicClips: [MediaContent] = {
        (0..<10).map { i in
            let titles = [
                "봄날 (Spring Day)", "작은 것들을 위한 시", "Dynamite (Korean Ver.)",
                "좋은 날 (Good Day)", "사랑을 했다", "팔색조",
                "Butter (Korean Ver.)", "어떻게 이별까지", "밤편지", "Eight"
            ]
            let artists = [
                "BTS", "BTS", "BTS", "IU", "iKON",
                "Rain", "BTS", "AKMU", "IU", "IU"
            ]
            let lyrics = [
                "보고 싶다 이렇게 말하니까 더 보고 싶다",
                "작은 것들을 위한 시 나의 모든 것",
                "빛나는 건 너의 미소 가장 소중한 것",
                "좋은 날 좋은 날 좋은 날",
                "사랑을 했다 우리가 만난 건 기적이었다",
                "나는 팔색조 매일 달라지는 나를 봐",
                "부드럽게 너에게 다가가는 나",
                "어떻게 이별까지 사랑하겠어",
                "이 밤 그날의 반딧불을 당신의 창 가까이",
                "영원히 소년이고 싶었어 우리의 시간"
            ]
            let levels = ["A2", "A2", "A1", "A1", "A2", "B1", "A1", "B1", "B1", "A2"]
            let scores = [0.35, 0.38, 0.2, 0.22, 0.4, 0.5, 0.18, 0.55, 0.52, 0.36]

            return MediaContent(
                title: titles[i],
                contentType: "music",
                source: artists[i],
                difficultyScore: scores[i],
                cefrLevel: levels[i],
                durationSeconds: 180 + i * 20,
                transcriptKr: lyrics[i],
                tags: ["music", "kpop"]
            )
        }
    }()
}

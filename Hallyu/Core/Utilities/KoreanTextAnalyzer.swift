import Foundation

struct TextAnalysis {
    let tokens: [String]
    let uniqueTokens: Set<String>
    let koreanCharacterCount: Int
    let totalCharacterCount: Int
    let difficultyScore: Double
    let estimatedCEFRLevel: String
    let frequencyProfile: FrequencyProfile
    let detectedGrammarPatterns: [String]
}

struct FrequencyProfile {
    let knownByFrequency: Int
    let totalTokens: Int
    let highFrequencyRatio: Double
    let midFrequencyRatio: Double
    let lowFrequencyRatio: Double
}

enum KoreanTextAnalyzer {

    // MARK: - Bundled Frequency List (Top Korean words by media frequency)

    static let frequencyList: [String: Int] = {
        let words: [(String, Int)] = [
            // Rank 1-50: Ultra-high frequency
            ("나", 1), ("는", 2), ("이", 3), ("가", 4), ("을", 5),
            ("를", 6), ("에", 7), ("의", 8), ("하다", 9), ("있다", 10),
            ("것", 11), ("수", 12), ("그", 13), ("되다", 14), ("않다", 15),
            ("없다", 16), ("사람", 17), ("우리", 18), ("그것", 19), ("아니다", 20),
            ("보다", 21), ("때", 22), ("말", 23), ("좋다", 24), ("알다", 25),
            ("오다", 26), ("가다", 27), ("주다", 28), ("대하다", 29), ("같다", 30),
            ("네", 31), ("아", 32), ("안", 33), ("뭐", 34), ("왜", 35),
            ("어디", 36), ("언제", 37), ("누구", 38), ("어떻게", 39), ("정말", 40),
            ("진짜", 41), ("다", 42), ("더", 43), ("또", 44), ("잘", 45),
            ("여기", 46), ("거기", 47), ("저기", 48), ("이거", 49), ("저", 50),
            // Rank 51-100: Very high frequency
            ("먹다", 51), ("마시다", 52), ("자다", 53), ("일어나다", 54), ("앉다", 55),
            ("서다", 56), ("걷다", 57), ("뛰다", 58), ("만나다", 59), ("헤어지다", 60),
            ("사랑", 61), ("친구", 62), ("가족", 63), ("엄마", 64), ("아빠", 65),
            ("형", 66), ("누나", 67), ("동생", 68), ("선생님", 69), ("학생", 70),
            ("학교", 71), ("회사", 72), ("집", 73), ("방", 74), ("문", 75),
            ("물", 76), ("밥", 77), ("오늘", 78), ("내일", 79), ("어제", 80),
            ("지금", 81), ("시간", 82), ("날씨", 83), ("감사", 84), ("미안", 85),
            ("괜찮다", 86), ("예쁘다", 87), ("크다", 88), ("작다", 89), ("많다", 90),
            ("적다", 91), ("새롭다", 92), ("쉽다", 93), ("어렵다", 94), ("빠르다", 95),
            ("느리다", 96), ("높다", 97), ("낮다", 98), ("기다리다", 99), ("생각하다", 100),
            // Rank 101-200: High frequency
            ("전화", 101), ("돈", 102), ("일", 103), ("말하다", 104), ("듣다", 105),
            ("읽다", 106), ("쓰다", 107), ("배우다", 108), ("가르치다", 109), ("찾다", 110),
            ("알려주다", 111), ("도와주다", 112), ("시작하다", 113), ("끝나다", 114), ("결혼", 115),
            ("약속", 116), ("여행", 117), ("음식", 118), ("노래", 119), ("영화", 120),
            ("드라마", 121), ("뉴스", 122), ("책", 123), ("사진", 124), ("꿈", 125),
            ("마음", 126), ("기분", 127), ("행복", 128), ("슬프다", 129), ("화나다", 130),
            ("웃다", 131), ("울다", 132), ("놀다", 133), ("쉬다", 134), ("운동", 135),
            ("공부", 136), ("숙제", 137), ("시험", 138), ("문제", 139), ("대답", 140),
            ("질문", 141), ("이름", 142), ("나이", 143), ("생일", 144), ("선물", 145),
            ("계절", 146), ("봄", 147), ("여름", 148), ("가을", 149), ("겨울", 150),
            ("비", 151), ("눈", 152), ("바람", 153), ("하늘", 154), ("바다", 155),
            ("산", 156), ("꽃", 157), ("나무", 158), ("동물", 159), ("고양이", 160),
            ("강아지", 161), ("버스", 162), ("지하철", 163), ("택시", 164), ("비행기", 165),
            ("병원", 166), ("은행", 167), ("식당", 168), ("카페", 169), ("마트", 170),
            ("가게", 171), ("공원", 172), ("역", 173), ("길", 174), ("옷", 175),
            ("신발", 176), ("모자", 177), ("색", 178), ("빨간", 179), ("파란", 180),
            ("하얀", 181), ("검은", 182), ("노란", 183), ("아침", 184), ("점심", 185),
            ("저녁", 186), ("밤", 187), ("월요일", 188), ("화요일", 189), ("수요일", 190),
            ("목요일", 191), ("금요일", 192), ("토요일", 193), ("일요일", 194), ("숫자", 195),
            ("하나", 196), ("둘", 197), ("셋", 198), ("넷", 199), ("다섯", 200),
            // Rank 201-400: Medium frequency (A2-B1 level)
            ("여섯", 201), ("일곱", 202), ("여덟", 203), ("아홉", 204), ("열", 205),
            ("백", 206), ("천", 207), ("만", 208), ("원", 209), ("개", 210),
            ("번", 211), ("째", 212), ("그러나", 213), ("그래서", 214), ("그런데", 215),
            ("하지만", 216), ("그리고", 217), ("또는", 218), ("만약", 219), ("아마", 220),
            ("반드시", 221), ("이미", 222), ("아직", 223), ("벌써", 224), ("항상", 225),
            ("보통", 226), ("가끔", 227), ("자주", 228), ("다시", 229), ("함께", 230),
            ("혼자", 231), ("특히", 232), ("제일", 233), ("매우", 234), ("조금", 235),
            ("많이", 236), ("전혀", 237), ("별로", 238), ("꽤", 239), ("상당히", 240),
            ("필요하다", 241), ("원하다", 242), ("바라다", 243), ("느끼다", 244), ("믿다", 245),
            ("기억하다", 246), ("잊다", 247), ("이해하다", 248), ("설명하다", 249), ("준비하다", 250),
            ("바꾸다", 251), ("고치다", 252), ("만들다", 253), ("사용하다", 254), ("놓다", 255),
            ("잡다", 256), ("열다", 257), ("닫다", 258), ("켜다", 259), ("끄다", 260),
            ("입다", 261), ("벗다", 262), ("신다", 263), ("씻다", 264), ("타다", 265),
            ("내리다", 266), ("올라가다", 267), ("내려가다", 268), ("들어가다", 269), ("나가다", 270),
            ("나오다", 271), ("돌아가다", 272), ("돌아오다", 273), ("데려가다", 274), ("데려오다", 275),
            ("보내다", 276), ("받다", 277), ("주문하다", 278), ("계산하다", 279), ("예약하다", 280),
            ("직업", 281), ("의사", 282), ("간호사", 283), ("경찰", 284), ("소방관", 285),
            ("요리사", 286), ("운전사", 287), ("회사원", 288), ("대학생", 289), ("부모님", 290),
            ("할머니", 291), ("할아버지", 292), ("아들", 293), ("딸", 294), ("남편", 295),
            ("아내", 296), ("남자", 297), ("여자", 298), ("아이", 299), ("어른", 300),
            ("머리", 301), ("얼굴", 302), ("코", 303),
            ("귀", 306), ("손", 307), ("발", 308), ("다리", 309), ("몸", 310),
            ("건강", 311), ("아프다", 312), ("약", 313), ("감기", 314),
            ("기침", 316), ("컴퓨터", 317), ("인터넷", 319), ("메시지", 320),
            ("편지", 321), ("신문", 322), ("잡지", 323), ("라디오", 324), ("텔레비전", 325),
            ("문화", 335), ("역사", 336), ("전통", 337), ("사회", 338), ("경제", 339),
            ("정치", 340), ("교육", 341), ("환경", 342), ("과학", 343), ("기술", 344),
            ("예술", 345), ("음악", 346), ("미술", 347), ("춤", 348), ("연극", 349),
            ("소설", 350), ("그림", 352), ("사건", 353), ("기사", 355),
            ("의견", 358), ("결과", 360), ("변화", 361), ("발전", 362),
            ("계획", 363), ("목표", 364), ("성공", 365), ("실패", 366),
            ("노력", 367), ("경험", 368), ("기회", 369), ("관계", 371),
            ("상황", 372), ("방법", 375), ("이유", 376), ("영향", 378),
            ("중요하다", 380), ("가능하다", 382), ("재미있다", 386), ("무섭다", 390),
            ("안녕하세요", 401), ("감사합니다", 402), ("죄송합니다", 403),
        ]
        var dict: [String: Int] = [:]
        for (word, rank) in words {
            dict[word] = rank
        }
        return dict
    }()

    /// Common Korean grammar patterns for detection
    static let grammarPatterns: [(pattern: String, name: String, cefrLevel: String)] = [
        ("이에요", "copula -이에요/예요", "A1"),
        ("예요", "copula -이에요/예요", "A1"),
        ("입니다", "formal copula -입니다", "A1"),
        ("습니다", "formal ending -습니다/ㅂ니다", "A1"),
        ("아요", "polite ending -아/어요", "A1"),
        ("어요", "polite ending -아/어요", "A1"),
        ("세요", "honorific -세요", "A1"),
        ("고 싶", "desire -고 싶다", "A1"),
        ("을 수 있", "ability -을/ㄹ 수 있다", "A2"),
        ("ㄹ 수 있", "ability -을/ㄹ 수 있다", "A2"),
        ("아서", "cause/sequence -아/어서", "A2"),
        ("어서", "cause/sequence -아/어서", "A2"),
        ("지만", "contrast -지만", "A2"),
        ("으면", "conditional -으면/면", "A2"),
        ("고 있", "progressive -고 있다", "A2"),
        ("는 것 같", "conjecture -는 것 같다", "B1"),
        ("기 때문에", "reason -기 때문에", "B1"),
        ("도록", "purpose/extent -도록", "B1"),
        ("으려고", "intention -으려고/려고", "B1"),
        ("려고", "intention -으려고/려고", "B1"),
        ("는데", "background -는데", "A2"),
        ("을까요", "suggestion -을까요/ㄹ까요", "A2"),
        ("아야 하", "obligation -아/어야 하다", "A2"),
        ("어야 하", "obligation -아/어야 하다", "A2"),
        ("더라고요", "retrospective -더라고요", "B1"),
        ("잖아요", "shared knowledge -잖아요", "B1"),
        ("거든요", "reason-giving -거든요", "B1"),
        ("다면", "hypothetical -다면", "B2"),
        ("더니", "observation -더니", "B2"),
        ("는 바람에", "unintended cause -는 바람에", "B2"),
    ]

    // MARK: - Analysis

    /// Analyze a Korean text and return vocabulary tokens, difficulty, grammar patterns, etc.
    static func analyzeText(_ korean: String) -> TextAnalysis {
        let tokens = tokenize(korean)
        let uniqueTokens = Set(tokens)
        let koreanCount = HangulUtilities.koreanCharacterCount(korean)
        let freqProfile = computeFrequencyProfile(tokens: tokens)
        let detectedPatterns = detectGrammarPatterns(in: korean)
        let difficulty = estimateDifficulty(
            tokens: tokens,
            uniqueTokens: uniqueTokens,
            frequencyProfile: freqProfile,
            grammarComplexity: detectedPatterns.count
        )
        let level = estimateCEFRLevel(difficultyScore: difficulty)

        return TextAnalysis(
            tokens: tokens,
            uniqueTokens: uniqueTokens,
            koreanCharacterCount: koreanCount,
            totalCharacterCount: korean.count,
            difficultyScore: difficulty,
            estimatedCEFRLevel: level,
            frequencyProfile: freqProfile,
            detectedGrammarPatterns: detectedPatterns
        )
    }

    /// Simple whitespace + punctuation tokenizer for Korean text
    static func tokenize(_ text: String) -> [String] {
        let punctuation = CharacterSet.punctuationCharacters
            .union(.whitespaces)
            .union(.newlines)

        return text.unicodeScalars
            .split { punctuation.contains($0) }
            .map { String($0) }
            .filter { !$0.isEmpty && HangulUtilities.containsKorean($0) }
    }

    /// Estimate vocabulary coverage for a learner given their known words
    static func estimateCoverage(text: String, knownWords: Set<String>) -> Double {
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return 1.0 }

        let knownCount = tokens.filter { knownWords.contains($0) }.count
        return Double(knownCount) / Double(tokens.count)
    }

    // MARK: - Frequency Analysis

    /// Look up the frequency rank of a word. Returns nil if not in the list.
    static func frequencyRank(for word: String) -> Int? {
        frequencyList[word]
    }

    /// Compute a frequency profile for a set of tokens
    static func computeFrequencyProfile(tokens: [String]) -> FrequencyProfile {
        guard !tokens.isEmpty else {
            return FrequencyProfile(knownByFrequency: 0, totalTokens: 0, highFrequencyRatio: 0, midFrequencyRatio: 0, lowFrequencyRatio: 0)
        }

        var highCount = 0  // rank 1-100
        var midCount = 0   // rank 101-300
        var lowCount = 0   // rank 301+ or unknown

        for token in tokens {
            if let rank = frequencyList[token] {
                if rank <= 100 {
                    highCount += 1
                } else if rank <= 300 {
                    midCount += 1
                } else {
                    lowCount += 1
                }
            } else {
                lowCount += 1
            }
        }

        let total = Double(tokens.count)
        let knownCount = tokens.filter { frequencyList[$0] != nil }.count

        return FrequencyProfile(
            knownByFrequency: knownCount,
            totalTokens: tokens.count,
            highFrequencyRatio: Double(highCount) / total,
            midFrequencyRatio: Double(midCount) / total,
            lowFrequencyRatio: Double(lowCount) / total
        )
    }

    // MARK: - Grammar Detection

    /// Detect grammar patterns present in the text
    static func detectGrammarPatterns(in text: String) -> [String] {
        var detected: [String] = []
        for entry in grammarPatterns {
            if text.contains(entry.pattern) && !detected.contains(entry.name) {
                detected.append(entry.name)
            }
        }
        return detected
    }

    // MARK: - Difficulty

    /// Estimate difficulty score (0.0 = easiest, 1.0 = hardest)
    static func estimateDifficulty(tokens: [String], uniqueTokens: Set<String>) -> Double {
        let profile = computeFrequencyProfile(tokens: tokens)
        return estimateDifficulty(tokens: tokens, uniqueTokens: uniqueTokens, frequencyProfile: profile, grammarComplexity: 0)
    }

    /// Estimate difficulty with full context including frequency and grammar
    static func estimateDifficulty(tokens: [String], uniqueTokens: Set<String>, frequencyProfile: FrequencyProfile, grammarComplexity: Int) -> Double {
        guard !tokens.isEmpty else { return 0.0 }

        // Factor 1: Lexical diversity (type-token ratio)
        let ttr = Double(uniqueTokens.count) / Double(tokens.count)

        // Factor 2: Frequency coverage (more low-frequency words = harder)
        let frequencyDifficulty = frequencyProfile.lowFrequencyRatio

        // Factor 3: Average token length (longer words tend to be more complex)
        let avgLength = Double(tokens.reduce(0) { $0 + $1.count }) / Double(tokens.count)
        let lengthFactor = min(avgLength / 6.0, 1.0)

        // Factor 4: Text length (longer texts are harder to process)
        let lengthDifficulty = min(Double(tokens.count) / 100.0, 1.0)

        // Factor 5: Grammar complexity
        let grammarFactor = min(Double(grammarComplexity) / 10.0, 1.0)

        // Weighted combination
        let difficulty = ttr * 0.25 + frequencyDifficulty * 0.3 + lengthFactor * 0.15 + lengthDifficulty * 0.15 + grammarFactor * 0.15
        return min(max(difficulty, 0.0), 1.0)
    }

    /// Map difficulty score to estimated CEFR level
    static func estimateCEFRLevel(difficultyScore: Double) -> String {
        switch difficultyScore {
        case 0.0..<0.2: return "pre-A1"
        case 0.2..<0.35: return "A1"
        case 0.35..<0.5: return "A2"
        case 0.5..<0.7: return "B1"
        default: return "B2"
        }
    }
}

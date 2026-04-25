import SwiftUI

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @AppStorage("selectedLanguage") var selectedLanguage: String = "en" {
        didSet { objectWillChange.send() }
    }

    let availableLanguages: [(code: String, displayName: String)] = [
        ("en", "English"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("zh-Hans", "中文")
    ]

    func string(_ key: L10nKey) -> String {
        translations[selectedLanguage]?[key] ?? translations["en"]![key] ?? key.rawValue
    }
}

// MARK: - Key definitions

enum L10nKey: String {
    // BackgroundMusicIntro
    case backgroundMusic
    case calmingMusicDescription
    case useEarphones
    case adjustVolume
    case ok
    case continueButton
    case skip

    // OnboardingFlow / CarouselPage
    case carouselTitle1
    case carouselSubtitle1
    case carouselTitle2
    case carouselSubtitle2
    case carouselTitle3
    case carouselSubtitle3

    // PurposeSelection
    case purposeTitle
    case purposeSubtitle
    case purposeRelieveStress
    case purposeFallAsleep
    case purposeFeelCalm
    case purposeEaseAnxiety
    case purposeIncreaseHappiness
    case purposeBoostEnergy

    // TextureSelection
    case textureTitle
    case textureSubtitle
    case textureNature
    case textureLight
    case textureFood
    case textureParticles

    // SoundSelection
    case soundTitle
    case soundSubtitle
    case soundNature
    case soundNatureSubtitle
    case soundHealing
    case soundHealingSubtitle
    case soundDeepSleep
    case soundDeepSleepSubtitle
    case soundASMR
    case soundASMRSubtitle
    case soundAmbient
    case soundAmbientSubtitle

    // BreathingQuestion
    case breathingTitle
    case yes
    case no

    // VibrationSelection
    case vibrationTitle
    case vibrationSubtitle
    case vibrationSoft
    case vibrationMedium
    case vibrationHard
    case vibrationOff

    // StruggleSelection
    case struggleTitle
    case struggleSubtitle
    case struggleAnxiety
    case struggleDepression
    case struggleSleepDisorder
    case struggleADHD
    case strugglePTSD
    case struggleOCD
    case struggleBipolar
    case strugglePanic

    // ReminderSelection
    case reminderTitle
    case reminderSubtitle
    case reminderMorning
    case reminderAfternoon
    case reminderEvening
    case reminderNight
    case setReminder

    // Paywall
    case lovedBy
    case millions
    case unlockInfinite
    case relaxation
    case reduceAnxiety
    case interactive
    case slimes
    case unlimited
    case textures
    case annualPlan
    case monthlyPlan
    case annualPrice
    case monthlyPrice
    case annualWeekly
    case monthlyWeekly
    case discount65
    case cancelAnytime
    case tryForFree
    case termsOfUse
    case privacyPolicy
    case restore

    // TodayView
    case premium
    case howAreYouFeeling
    case describeMood
    case whatsOnMind
    case letUsKnow
    case dontWantToShare
    case todaysRelaxation
    case start
    case recommendedForYou
    case selectionsBasedOnInterests
    case diySlimes
    case kaleidoscopes
    case particles
    case fluids

    // Mood
    case moodEnergized
    case moodRelaxed
    case moodStressed
    case moodAnxious
    case moodHurt
    case moodSad
    case moodAngry
    case moodAnnoyed

    // MindTopic
    case topicFamily
    case topicFriends
    case topicGames
    case topicSleep
    case topicPets
    case topicRelationship
    case topicSports
    case topicWork

    // RelaxView
    case categorySlimes
    case categoryDiySlimes
    case categoryKaleidoscopes
    case categoryParticles
    case categoryFluids
    case categoryOrbs
    case categoryFractal
    case categoryCampfire

    // TextureVariant names
    case variantFluidsMagenta
    case variantFluidsCyanMist
    case variantFluidsSunsetGold
    case variantKaleidoscopePurpleCyan
    case variantKaleidoscopeRoseGarden
    case variantKaleidoscopeEmerald
    case variantOrbsWarmSunset
    case variantOrbsDeepOcean
    case variantOrbsAurora
    case variantParticlesSparkle
    case variantParticlesFireflies
    case variantParticlesEmberRain
    case variantSlimePastel
    case variantSlimeMint
    case variantSlimeBubblegum
    case variantSlimeFur
    case variantSlimeWeave
    case variantSlimeVelvet
    case variantSlimeMetalMesh
    case variantSlimeWool
    case variantSlimeTeddy
    case variantSlimeFrosty
    case variantWavesDeepBlue
    case variantWavesTropical
    case variantWavesMoonlight
    case variantFractalRainbow
    case variantFractalDeepSpace
    case variantFractalWarmSunset

    // BreathView
    case breatheIn
    case hold
    case breatheOut
    case stop

    // SleepView
    case sleepStories
    case soundRain
    case soundOceanWaves
    case soundThunder
    case soundForest
    case soundCampfire
    case soundWhiteNoise

    // ProfileView
    case nagiUser
    case profilePremium
    case profileFree
    case notifications
    case vibration
    case sound
    case manageSubscription
    case restorePurchases
    case termsOfUseProfile
    case privacyPolicyProfile
    case language
    case settings
    case subscription
    case about

    // Today - additional sections
    case meditations
    case meditationsSubtitle
    case embracingLove
    case soothingAnxiety
    case hopeAndHealing
    case yourFavorite
    case yourFavoriteSubtitle
    case noFavoritesYet
    case explore
    case forBetterSleeping
    case forBetterSleepingSubtitle
    case relaxMixes
    case whiteNoiseSlimes
    case moodDiary
    case moodDiaryQuestion
    case checkMyMood

    // RelaxView header / CategoryDetailView
    case relaxHeaderSubtitle
    case chooseVariant
}

// MARK: - Translation tables

private let translations: [String: [L10nKey: String]] = [
    "en": enTranslations,
    "ja": jaTranslations,
    "ko": koTranslations,
    "zh-Hans": zhTranslations
]

private let enTranslations: [L10nKey: String] = [
    .backgroundMusic: "Background music",
    .calmingMusicDescription: "Calming music can help you ease tension and relax your body.",
    .useEarphones: "Use your earphones for a better experience",
    .adjustVolume: "Adjust the volume to a comfortable level",
    .ok: "OK",
    .continueButton: "Continue",
    .skip: "Skip",
    .carouselTitle1: "Reduce stress with particles!",
    .carouselSubtitle1: "Dive into a wonderful world of vivid",
    .carouselTitle2: "Have fun with soothing slimes!",
    .carouselSubtitle2: "Lose yourself in the sensory paradise of realistic textures",
    .carouselTitle3: "Enjoy calm background music!",
    .carouselSubtitle3: "Discover beautiful sounds that will create a peaceful, soothing atmosphere",
    .purposeTitle: "What's your purpose now?",
    .purposeSubtitle: "We'll find techniques that work best for you.",
    .purposeRelieveStress: "Relieve stress",
    .purposeFallAsleep: "Fall asleep",
    .purposeFeelCalm: "Feel calm",
    .purposeEaseAnxiety: "Ease anxiety",
    .purposeIncreaseHappiness: "Increase happiness",
    .purposeBoostEnergy: "Boost energy",
    .textureTitle: "What types of textures do you like best?",
    .textureSubtitle: "We'll tailor content to your needs",
    .textureNature: "Nature",
    .textureLight: "Light",
    .textureFood: "Food",
    .textureParticles: "Particles",
    .soundTitle: "Choose sounds and music that you like most",
    .soundSubtitle: "We'll tune up sounds based on your preferences",
    .soundNature: "Nature sounds",
    .soundNatureSubtitle: "Tropical wildlife, birds, campfire, etc",
    .soundHealing: "Healing music",
    .soundHealingSubtitle: "Soothing, therapeutic tracks, etc",
    .soundDeepSleep: "Deep sleep",
    .soundDeepSleepSubtitle: "Ambient beats, tranquil music, etc",
    .soundASMR: "ASMR",
    .soundASMRSubtitle: "Water drops, leaves, cat purring, etc",
    .soundAmbient: "Ambient sounds",
    .soundAmbientSubtitle: "Forest, pond, sea, etc",
    .breathingTitle: "Do you want to reduce stress with breathing exercises?",
    .yes: "Yes",
    .no: "No",
    .vibrationTitle: "What vibration mode do you prefer?",
    .vibrationSubtitle: "Tap on different options to feel the sensation",
    .vibrationSoft: "Soft",
    .vibrationMedium: "Medium",
    .vibrationHard: "Hard",
    .vibrationOff: "Off",
    .struggleTitle: "What do you want to ease?",
    .struggleSubtitle: "We'll suggest content that fits your mood. This is not medical advice.",
    .struggleAnxiety: "Feeling restless",
    .struggleDepression: "Low mood",
    .struggleSleepDisorder: "Trouble sleeping",
    .struggleADHD: "Easily distracted",
    .strugglePTSD: "Overwhelmed by thoughts",
    .struggleOCD: "Repetitive thoughts",
    .struggleBipolar: "Mood swings",
    .strugglePanic: "Sudden tension",
    .reminderTitle: "Let us remind you to relax",
    .reminderSubtitle: "Relaxing for a few minutes every day is proven to reduce stress by 38%",
    .reminderMorning: "In the morning",
    .reminderAfternoon: "In the afternoon",
    .reminderEvening: "In the evening",
    .reminderNight: "At night",
    .setReminder: "Set a reminder",
    .lovedBy: "Loved by ",
    .millions: "Millions",
    .unlockInfinite: "Unlock Infinite",
    .relaxation: "Relaxation",
    .reduceAnxiety: "Reduce anxiety and regain your focus",
    .interactive: "Interactive",
    .slimes: "Slimes",
    .unlimited: "Unlimited",
    .textures: "Textures",
    .annualPlan: "Annual + 3 day free",
    .monthlyPlan: "MONTHLY",
    .annualPrice: "¥7,000 per year",
    .monthlyPrice: "¥2,000 per month",
    .annualWeekly: "¥135 / week",
    .monthlyWeekly: "¥500 / week",
    .discount65: "65% OFF",
    .cancelAnytime: "Cancel anytime",
    .tryForFree: "Try for Free",
    .termsOfUse: "Terms of use",
    .privacyPolicy: "Privacy policy",
    .restore: "Restore",
    .premium: "Premium!",
    .howAreYouFeeling: "How're you feeling now?",
    .describeMood: "Describe your mood to help us pick\nthe right techniques for you",
    .whatsOnMind: "What's on your mind?",
    .letUsKnow: "Let us know to help personalize\nyour relaxation session",
    .dontWantToShare: "Don't want to share? Click here to relax",
    .todaysRelaxation: "Today's relaxation",
    .start: "Start",
    .recommendedForYou: "Recommended for you",
    .selectionsBasedOnInterests: "Selections based on your interests",
    .diySlimes: "DIY slimes",
    .kaleidoscopes: "Kaleidoscopes",
    .particles: "Particles",
    .fluids: "Fluids",
    .moodEnergized: "Energized",
    .moodRelaxed: "Relaxed",
    .moodStressed: "Stressed",
    .moodAnxious: "Anxious",
    .moodHurt: "Hurt",
    .moodSad: "Sad",
    .moodAngry: "Angry",
    .moodAnnoyed: "Annoyed",
    .topicFamily: "Family",
    .topicFriends: "Friends",
    .topicGames: "Games",
    .topicSleep: "Sleep",
    .topicPets: "Pets",
    .topicRelationship: "Relationship",
    .topicSports: "Sports",
    .topicWork: "Work",
    .categorySlimes: "Slimes",
    .categoryDiySlimes: "DIY slimes",
    .categoryKaleidoscopes: "Kaleidoscopes",
    .categoryParticles: "Particles",
    .categoryFluids: "Fluids",
    .categoryOrbs: "Orbs",
    .categoryFractal: "Fractal",
    .categoryCampfire: "Campfire",
    .variantFluidsMagenta: "Magenta",
    .variantFluidsCyanMist: "Cyan Mist",
    .variantFluidsSunsetGold: "Sunset Gold",
    .variantKaleidoscopePurpleCyan: "Purple Cyan",
    .variantKaleidoscopeRoseGarden: "Rose Garden",
    .variantKaleidoscopeEmerald: "Emerald",
    .variantOrbsWarmSunset: "Warm Sunset",
    .variantOrbsDeepOcean: "Deep Ocean",
    .variantOrbsAurora: "Aurora",
    .variantParticlesSparkle: "Sparkle",
    .variantParticlesFireflies: "Fireflies",
    .variantParticlesEmberRain: "Ember Rain",
    .variantSlimePastel: "Pastel",
    .variantSlimeMint: "Mint",
    .variantSlimeBubblegum: "Bubblegum",
    .variantSlimeFur: "Fur",
    .variantSlimeWeave: "Weave",
    .variantSlimeVelvet: "Velvet",
    .variantSlimeMetalMesh: "Metal Mesh",
    .variantSlimeWool: "Wool",
    .variantSlimeTeddy: "Teddy",
    .variantSlimeFrosty: "Frosty",
    .variantWavesDeepBlue: "Deep Blue",
    .variantWavesTropical: "Tropical",
    .variantWavesMoonlight: "Moonlight",
    .variantFractalRainbow: "Rainbow",
    .variantFractalDeepSpace: "Deep Space",
    .variantFractalWarmSunset: "Warm Sunset",
    .breatheIn: "Breathe In",
    .hold: "Hold",
    .breatheOut: "Breathe Out",
    .stop: "Stop",
    .sleepStories: "Sleep Stories",
    .soundRain: "Rain",
    .soundOceanWaves: "Ocean Waves",
    .soundThunder: "Thunder",
    .soundForest: "Forest",
    .soundCampfire: "Campfire",
    .soundWhiteNoise: "White Noise",
    .nagiUser: "Nagi User",
    .profilePremium: "Premium",
    .profileFree: "Free",
    .notifications: "Notifications",
    .vibration: "Vibration",
    .sound: "Sound",
    .manageSubscription: "Manage Subscription",
    .restorePurchases: "Restore Purchases",
    .termsOfUseProfile: "Terms of Use",
    .privacyPolicyProfile: "Privacy Policy",
    .language: "Language",
    .settings: "Settings",
    .subscription: "Subscription",
    .about: "About",
    .meditations: "Meditations",
    .meditationsSubtitle: "Audio meditations for peace of mind",
    .embracingLove: "Embracing Love",
    .soothingAnxiety: "Soothing Anxiety",
    .hopeAndHealing: "Hope & Healing",
    .yourFavorite: "Your favorite",
    .yourFavoriteSubtitle: "Here is what you liked",
    .noFavoritesYet: "You haven't liked anything yet",
    .explore: "Explore",
    .forBetterSleeping: "For your better sleeping",
    .forBetterSleepingSubtitle: "Sleep sounds collections and other",
    .relaxMixes: "Relax Mixes",
    .whiteNoiseSlimes: "White Noise Slimes",
    .moodDiary: "Mood diary",
    .moodDiaryQuestion: "How are you feeling today?",
    .checkMyMood: "Check My Mood",
    .relaxHeaderSubtitle: "Soothing tactile and sound experience",
    .chooseVariant: "Choose a texture"
]

private let jaTranslations: [L10nKey: String] = [
    .backgroundMusic: "バックグラウンドミュージック",
    .calmingMusicDescription: "リラックスできる音楽が、緊張をほぐし体をリラックスさせます。",
    .useEarphones: "より良い体験のためにイヤホンをご使用ください",
    .adjustVolume: "快適な音量に調整してください",
    .ok: "OK",
    .continueButton: "続ける",
    .skip: "スキップ",
    .carouselTitle1: "パーティクルでストレス解消！",
    .carouselSubtitle1: "鮮やかな世界に飛び込もう",
    .carouselTitle2: "癒しのスライムで楽しもう！",
    .carouselSubtitle2: "リアルな質感の感覚の楽園に浸ろう",
    .carouselTitle3: "穏やかなBGMを楽しもう！",
    .carouselSubtitle3: "平和で癒しの雰囲気を生み出す美しいサウンドを発見しよう",
    .purposeTitle: "今の目的は何ですか？",
    .purposeSubtitle: "あなたに最適なテクニックを見つけます。",
    .purposeRelieveStress: "ストレス解消",
    .purposeFallAsleep: "眠りに落ちる",
    .purposeFeelCalm: "落ち着く",
    .purposeEaseAnxiety: "不安を和らげる",
    .purposeIncreaseHappiness: "幸福感を高める",
    .purposeBoostEnergy: "エネルギーを高める",
    .textureTitle: "どんな質感が好きですか？",
    .textureSubtitle: "あなたのニーズに合わせてコンテンツを調整します",
    .textureNature: "自然",
    .textureLight: "光",
    .textureFood: "食べ物",
    .textureParticles: "パーティクル",
    .soundTitle: "好きなサウンドを選んでください",
    .soundSubtitle: "好みに基づいてサウンドを調整します",
    .soundNature: "自然の音",
    .soundNatureSubtitle: "熱帯の野生動物、鳥、焚き火など",
    .soundHealing: "ヒーリングミュージック",
    .soundHealingSubtitle: "癒しのセラピートラックなど",
    .soundDeepSleep: "深い眠り",
    .soundDeepSleepSubtitle: "アンビエントビート、穏やかな音楽など",
    .soundASMR: "ASMR",
    .soundASMRSubtitle: "水滴、葉っぱ、猫のゴロゴロなど",
    .soundAmbient: "アンビエントサウンド",
    .soundAmbientSubtitle: "森、池、海など",
    .breathingTitle: "呼吸法でストレスを軽減したいですか？",
    .yes: "はい",
    .no: "いいえ",
    .vibrationTitle: "好みの振動モードは？",
    .vibrationSubtitle: "各オプションをタップして感覚を試してください",
    .vibrationSoft: "弱",
    .vibrationMedium: "中",
    .vibrationHard: "強",
    .vibrationOff: "オフ",
    .struggleTitle: "どんな気分を和らげたいですか？",
    .struggleSubtitle: "あなたの気分に合うコンテンツを提案します。これは医学的助言ではありません。",
    .struggleAnxiety: "落ち着かない",
    .struggleDepression: "気分が沈む",
    .struggleSleepDisorder: "眠りにくい",
    .struggleADHD: "集中しづらい",
    .strugglePTSD: "考えに押しつぶされそう",
    .struggleOCD: "繰り返す思考",
    .struggleBipolar: "気分の波",
    .strugglePanic: "急な緊張",
    .reminderTitle: "リラックスのリマインダーを設定しましょう",
    .reminderSubtitle: "毎日数分リラックスすることで、ストレスが38%軽減されることが証明されています",
    .reminderMorning: "朝",
    .reminderAfternoon: "午後",
    .reminderEvening: "夕方",
    .reminderNight: "夜",
    .setReminder: "リマインダーを設定",
    .lovedBy: "愛用者 ",
    .millions: "数百万人",
    .unlockInfinite: "無限の",
    .relaxation: "リラクゼーション",
    .reduceAnxiety: "不安を軽減し、集中力を取り戻す",
    .interactive: "インタラクティブ",
    .slimes: "スライム",
    .unlimited: "無制限",
    .textures: "テクスチャ",
    .annualPlan: "年間 + 3日間無料",
    .monthlyPlan: "月間",
    .annualPrice: "¥7,000 / 年",
    .monthlyPrice: "¥2,000 / 月",
    .annualWeekly: "¥135 / 週",
    .monthlyWeekly: "¥500 / 週",
    .discount65: "65% OFF",
    .cancelAnytime: "いつでもキャンセル可能",
    .tryForFree: "無料で試す",
    .termsOfUse: "利用規約",
    .privacyPolicy: "プライバシーポリシー",
    .restore: "復元",
    .premium: "プレミアム！",
    .howAreYouFeeling: "今の気分は？",
    .describeMood: "気分を教えて、最適なテクニックを選びます",
    .whatsOnMind: "何が頭にありますか？",
    .letUsKnow: "教えていただくと、リラクゼーションセッションをカスタマイズできます",
    .dontWantToShare: "共有しない？こちらをタップしてリラックスしましょう",
    .todaysRelaxation: "今日のリラクゼーション",
    .start: "スタート",
    .recommendedForYou: "あなたへのおすすめ",
    .selectionsBasedOnInterests: "あなたの興味に基づいたセレクション",
    .diySlimes: "DIYスライム",
    .kaleidoscopes: "万華鏡",
    .particles: "パーティクル",
    .fluids: "フルイド",
    .moodEnergized: "元気",
    .moodRelaxed: "リラックス",
    .moodStressed: "ストレス",
    .moodAnxious: "不安",
    .moodHurt: "傷ついた",
    .moodSad: "悲しい",
    .moodAngry: "怒り",
    .moodAnnoyed: "イライラ",
    .topicFamily: "家族",
    .topicFriends: "友達",
    .topicGames: "ゲーム",
    .topicSleep: "睡眠",
    .topicPets: "ペット",
    .topicRelationship: "恋愛",
    .topicSports: "スポーツ",
    .topicWork: "仕事",
    .categorySlimes: "スライム",
    .categoryDiySlimes: "DIYスライム",
    .categoryKaleidoscopes: "万華鏡",
    .categoryParticles: "パーティクル",
    .categoryFluids: "フルイド",
    .categoryOrbs: "オーブ",
    .categoryFractal: "フラクタル",
    .categoryCampfire: "焚き火",
    .variantFluidsMagenta: "マゼンタ",
    .variantFluidsCyanMist: "シアンミスト",
    .variantFluidsSunsetGold: "サンセットゴールド",
    .variantKaleidoscopePurpleCyan: "パープルシアン",
    .variantKaleidoscopeRoseGarden: "ローズガーデン",
    .variantKaleidoscopeEmerald: "エメラルド",
    .variantOrbsWarmSunset: "ウォームサンセット",
    .variantOrbsDeepOcean: "ディープオーシャン",
    .variantOrbsAurora: "オーロラ",
    .variantParticlesSparkle: "スパークル",
    .variantParticlesFireflies: "ホタル",
    .variantParticlesEmberRain: "残り火の雨",
    .variantSlimePastel: "パステル",
    .variantSlimeMint: "ミント",
    .variantSlimeBubblegum: "バブルガム",
    .variantSlimeFur: "ファー",
    .variantSlimeWeave: "織物",
    .variantSlimeVelvet: "ベルベット",
    .variantSlimeMetalMesh: "金属メッシュ",
    .variantSlimeWool: "ウール",
    .variantSlimeTeddy: "テディ",
    .variantSlimeFrosty: "霜",
    .variantWavesDeepBlue: "ディープブルー",
    .variantWavesTropical: "トロピカル",
    .variantWavesMoonlight: "ムーンライト",
    .variantFractalRainbow: "レインボー",
    .variantFractalDeepSpace: "ディープスペース",
    .variantFractalWarmSunset: "ウォームサンセット",
    .breatheIn: "吸う",
    .hold: "止める",
    .breatheOut: "吐く",
    .stop: "停止",
    .sleepStories: "睡眠ストーリー",
    .soundRain: "雨",
    .soundOceanWaves: "波の音",
    .soundThunder: "雷",
    .soundForest: "森",
    .soundCampfire: "焚き火",
    .soundWhiteNoise: "ホワイトノイズ",
    .nagiUser: "Nagiユーザー",
    .profilePremium: "プレミアム",
    .profileFree: "フリー",
    .notifications: "通知",
    .vibration: "バイブレーション",
    .sound: "サウンド",
    .manageSubscription: "サブスクリプション管理",
    .restorePurchases: "購入の復元",
    .termsOfUseProfile: "利用規約",
    .privacyPolicyProfile: "プライバシーポリシー",
    .language: "言語",
    .settings: "設定",
    .subscription: "サブスクリプション",
    .about: "について",
    .meditations: "瞑想",
    .meditationsSubtitle: "心の平穏のためのオーディオ瞑想",
    .embracingLove: "愛を受け入れる",
    .soothingAnxiety: "不安を和らげる",
    .hopeAndHealing: "希望と癒し",
    .yourFavorite: "お気に入り",
    .yourFavoriteSubtitle: "あなたがいいねしたもの",
    .noFavoritesYet: "まだお気に入りはありません",
    .explore: "探索する",
    .forBetterSleeping: "より良い睡眠のために",
    .forBetterSleepingSubtitle: "スリープサウンドコレクション",
    .relaxMixes: "リラックスミックス",
    .whiteNoiseSlimes: "ホワイトノイズスライム",
    .moodDiary: "気分日記",
    .moodDiaryQuestion: "今日の気分はどうですか？",
    .checkMyMood: "気分をチェック",
    .relaxHeaderSubtitle: "癒しの触覚と音の体験",
    .chooseVariant: "テクスチャを選ぶ"
]

private let koTranslations: [L10nKey: String] = [
    .backgroundMusic: "배경 음악",
    .calmingMusicDescription: "잔잔한 음악이 긴장을 풀고 몸을 편안하게 해줄 수 있어요.",
    .useEarphones: "더 좋은 경험을 위해 이어폰을 사용하세요",
    .adjustVolume: "편안한 볼륨으로 조절하세요",
    .ok: "확인",
    .continueButton: "계속",
    .skip: "건너뛰기",
    .carouselTitle1: "파티클로 스트레스 해소!",
    .carouselSubtitle1: "생생한 세계 속으로 빠져들어 보세요",
    .carouselTitle2: "부드러운 슬라임으로 즐겨요!",
    .carouselSubtitle2: "현실감 있는 질감의 감각 낙원에 빠져보세요",
    .carouselTitle3: "차분한 배경 음악을 즐겨요!",
    .carouselSubtitle3: "평화롭고 편안한 분위기를 만들어 주는 아름다운 소리를 발견하세요",
    .purposeTitle: "지금 목적이 무엇인가요?",
    .purposeSubtitle: "가장 잘 맞는 기법을 찾아드릴게요.",
    .purposeRelieveStress: "스트레스 해소",
    .purposeFallAsleep: "잠들기",
    .purposeFeelCalm: "차분해지기",
    .purposeEaseAnxiety: "불안 완화",
    .purposeIncreaseHappiness: "행복감 증가",
    .purposeBoostEnergy: "에너지 향상",
    .textureTitle: "어떤 질감을 가장 좋아하세요?",
    .textureSubtitle: "필요에 맞게 콘텐츠를 조정해 드릴게요",
    .textureNature: "자연",
    .textureLight: "빛",
    .textureFood: "음식",
    .textureParticles: "파티클",
    .soundTitle: "좋아하는 사운드를 선택하세요",
    .soundSubtitle: "선호도에 맞게 사운드를 조정해 드릴게요",
    .soundNature: "자연의 소리",
    .soundNatureSubtitle: "열대 야생동물, 새, 모닥불 등",
    .soundHealing: "힐링 음악",
    .soundHealingSubtitle: "편안하고 치유적인 트랙 등",
    .soundDeepSleep: "깊은 잠",
    .soundDeepSleepSubtitle: "앰비언트 비트, 잔잔한 음악 등",
    .soundASMR: "ASMR",
    .soundASMRSubtitle: "물방울, 나뭇잎, 고양이 골골 등",
    .soundAmbient: "앰비언트 사운드",
    .soundAmbientSubtitle: "숲, 연못, 바다 등",
    .breathingTitle: "호흡 운동으로 스트레스를 줄이고 싶으신가요?",
    .yes: "예",
    .no: "아니요",
    .vibrationTitle: "어떤 진동 모드를 선호하세요?",
    .vibrationSubtitle: "다른 옵션을 탭해서 느낌을 경험해 보세요",
    .vibrationSoft: "약",
    .vibrationMedium: "중",
    .vibrationHard: "강",
    .vibrationOff: "끄기",
    .struggleTitle: "어떤 기분을 달래고 싶으세요?",
    .struggleSubtitle: "당신의 기분에 맞는 콘텐츠를 제안할게요. 의학적 조언이 아닙니다.",
    .struggleAnxiety: "안절부절못함",
    .struggleDepression: "기분이 가라앉음",
    .struggleSleepDisorder: "잠들기 어려움",
    .struggleADHD: "집중이 어려움",
    .strugglePTSD: "생각에 압도됨",
    .struggleOCD: "반복되는 생각",
    .struggleBipolar: "기분 기복",
    .strugglePanic: "갑작스런 긴장",
    .reminderTitle: "편안히 쉬도록 알림을 설정해 드릴게요",
    .reminderSubtitle: "매일 몇 분 휴식하면 스트레스가 38% 줄어드는 것이 입증되었어요",
    .reminderMorning: "아침에",
    .reminderAfternoon: "오후에",
    .reminderEvening: "저녁에",
    .reminderNight: "밤에",
    .setReminder: "알림 설정",
    .lovedBy: "사랑받는 ",
    .millions: "수백만 명",
    .unlockInfinite: "무한한",
    .relaxation: "릴렉세이션",
    .reduceAnxiety: "불안을 줄이고 집중력을 되찾으세요",
    .interactive: "인터랙티브",
    .slimes: "슬라임",
    .unlimited: "무제한",
    .textures: "텍스처",
    .annualPlan: "연간 + 3일 무료",
    .monthlyPlan: "월간",
    .annualPrice: "₩9,900 / 년",
    .monthlyPrice: "₩3,300 / 월",
    .annualWeekly: "₩190 / 주",
    .monthlyWeekly: "₩760 / 주",
    .discount65: "65% 할인",
    .cancelAnytime: "언제든지 취소 가능",
    .tryForFree: "무료로 시작하기",
    .termsOfUse: "이용약관",
    .privacyPolicy: "개인정보처리방침",
    .restore: "복원",
    .premium: "프리미엄!",
    .howAreYouFeeling: "지금 기분이 어떠세요?",
    .describeMood: "기분을 알려주시면 최적의 기법을 선택해 드려요",
    .whatsOnMind: "무슨 생각이 드세요?",
    .letUsKnow: "알려주시면 릴렉세이션 세션을 맞춤화해 드려요",
    .dontWantToShare: "공유하기 싫으신가요? 여기를 탭해서 쉬어가세요",
    .todaysRelaxation: "오늘의 릴렉세이션",
    .start: "시작",
    .recommendedForYou: "추천",
    .selectionsBasedOnInterests: "관심사에 기반한 선택",
    .diySlimes: "DIY 슬라임",
    .kaleidoscopes: "만화경",
    .particles: "파티클",
    .fluids: "플루이드",
    .moodEnergized: "활기참",
    .moodRelaxed: "릴렉스",
    .moodStressed: "스트레스",
    .moodAnxious: "불안",
    .moodHurt: "상처받음",
    .moodSad: "슬픔",
    .moodAngry: "화남",
    .moodAnnoyed: "짜증남",
    .topicFamily: "가족",
    .topicFriends: "친구",
    .topicGames: "게임",
    .topicSleep: "수면",
    .topicPets: "반려동물",
    .topicRelationship: "연애",
    .topicSports: "스포츠",
    .topicWork: "일",
    .categorySlimes: "슬라임",
    .categoryDiySlimes: "DIY 슬라임",
    .categoryKaleidoscopes: "만화경",
    .categoryParticles: "파티클",
    .categoryFluids: "플루이드",
    .categoryOrbs: "오브",
    .categoryFractal: "프랙탈",
    .categoryCampfire: "모닥불",
    .variantFluidsMagenta: "마젠타",
    .variantFluidsCyanMist: "시안 미스트",
    .variantFluidsSunsetGold: "선셋 골드",
    .variantKaleidoscopePurpleCyan: "퍼플 시안",
    .variantKaleidoscopeRoseGarden: "로즈 가든",
    .variantKaleidoscopeEmerald: "에메랄드",
    .variantOrbsWarmSunset: "웜 선셋",
    .variantOrbsDeepOcean: "딥 오션",
    .variantOrbsAurora: "오로라",
    .variantParticlesSparkle: "스파클",
    .variantParticlesFireflies: "반딧불",
    .variantParticlesEmberRain: "잉걸불 비",
    .variantSlimePastel: "파스텔",
    .variantSlimeMint: "민트",
    .variantSlimeBubblegum: "버블검",
    .variantSlimeFur: "퍼",
    .variantSlimeWeave: "직물",
    .variantSlimeVelvet: "벨벳",
    .variantSlimeMetalMesh: "메탈 메쉬",
    .variantSlimeWool: "울",
    .variantSlimeTeddy: "테디",
    .variantSlimeFrosty: "서리",
    .variantWavesDeepBlue: "딥 블루",
    .variantWavesTropical: "트로피컬",
    .variantWavesMoonlight: "문라이트",
    .variantFractalRainbow: "레인보우",
    .variantFractalDeepSpace: "딥 스페이스",
    .variantFractalWarmSunset: "웜 선셋",
    .breatheIn: "들이쉬기",
    .hold: "멈추기",
    .breatheOut: "내쉬기",
    .stop: "정지",
    .sleepStories: "수면 이야기",
    .soundRain: "비",
    .soundOceanWaves: "파도",
    .soundThunder: "천둥",
    .soundForest: "숲",
    .soundCampfire: "모닥불",
    .soundWhiteNoise: "화이트 노이즈",
    .nagiUser: "Nagi 사용자",
    .profilePremium: "프리미엄",
    .profileFree: "무료",
    .notifications: "알림",
    .vibration: "진동",
    .sound: "사운드",
    .manageSubscription: "구독 관리",
    .restorePurchases: "구매 복원",
    .termsOfUseProfile: "이용약관",
    .privacyPolicyProfile: "개인정보처리방침",
    .language: "언어",
    .settings: "설정",
    .subscription: "구독",
    .about: "정보",
    .meditations: "명상",
    .meditationsSubtitle: "마음의 평화를 위한 오디오 명상",
    .embracingLove: "사랑 포용하기",
    .soothingAnxiety: "불안 달래기",
    .hopeAndHealing: "희망과 치유",
    .yourFavorite: "즐겨찾기",
    .yourFavoriteSubtitle: "좋아요를 누른 항목",
    .noFavoritesYet: "아직 좋아요가 없습니다",
    .explore: "탐색하기",
    .forBetterSleeping: "더 나은 수면을 위해",
    .forBetterSleepingSubtitle: "수면 사운드 컬렉션",
    .relaxMixes: "릴랙스 믹스",
    .whiteNoiseSlimes: "화이트 노이즈 슬라임",
    .moodDiary: "기분 일기",
    .moodDiaryQuestion: "오늘 기분이 어떠세요?",
    .checkMyMood: "내 기분 체크",
    .relaxHeaderSubtitle: "편안한 촉각과 소리 경험",
    .chooseVariant: "텍스처 선택"
]

private let zhTranslations: [L10nKey: String] = [
    .backgroundMusic: "背景音乐",
    .calmingMusicDescription: "舒缓的音乐可以帮助您释放紧张、放松身体。",
    .useEarphones: "建议使用耳机以获得更好的体验",
    .adjustVolume: "请将音量调节到舒适的水平",
    .ok: "好的",
    .continueButton: "继续",
    .skip: "跳过",
    .carouselTitle1: "用粒子效果减压！",
    .carouselSubtitle1: "沉浸在生动绚丽的世界中",
    .carouselTitle2: "享受舒缓的史莱姆！",
    .carouselSubtitle2: "沉浸在逼真质感的感官天堂",
    .carouselTitle3: "享受平静的背景音乐！",
    .carouselSubtitle3: "发现能创造平和放松氛围的美妙声音",
    .purposeTitle: "您现在的目的是什么？",
    .purposeSubtitle: "我们将为您找到最适合的技巧。",
    .purposeRelieveStress: "缓解压力",
    .purposeFallAsleep: "帮助入睡",
    .purposeFeelCalm: "感到平静",
    .purposeEaseAnxiety: "缓解焦虑",
    .purposeIncreaseHappiness: "增加幸福感",
    .purposeBoostEnergy: "提升活力",
    .textureTitle: "您最喜欢哪种质感？",
    .textureSubtitle: "我们将根据您的需求定制内容",
    .textureNature: "自然",
    .textureLight: "光影",
    .textureFood: "食物",
    .textureParticles: "粒子",
    .soundTitle: "选择您最喜欢的声音",
    .soundSubtitle: "我们将根据您的偏好调整声音",
    .soundNature: "自然之声",
    .soundNatureSubtitle: "热带野生动物、鸟鸣、篝火等",
    .soundHealing: "疗愈音乐",
    .soundHealingSubtitle: "舒缓、治疗性曲目等",
    .soundDeepSleep: "深度睡眠",
    .soundDeepSleepSubtitle: "环境节拍、宁静音乐等",
    .soundASMR: "ASMR",
    .soundASMRSubtitle: "水滴声、树叶声、猫咪咕噜声等",
    .soundAmbient: "环境音效",
    .soundAmbientSubtitle: "森林、池塘、海洋等",
    .breathingTitle: "您想通过呼吸练习来减压吗？",
    .yes: "是",
    .no: "否",
    .vibrationTitle: "您偏好哪种振动模式？",
    .vibrationSubtitle: "点击不同选项感受振动效果",
    .vibrationSoft: "轻柔",
    .vibrationMedium: "中等",
    .vibrationHard: "强烈",
    .vibrationOff: "关闭",
    .struggleTitle: "您想缓解什么样的心情？",
    .struggleSubtitle: "我们将推荐适合您心情的内容。这不是医学建议。",
    .struggleAnxiety: "坐立不安",
    .struggleDepression: "情绪低落",
    .struggleSleepDisorder: "难以入眠",
    .struggleADHD: "难以集中",
    .strugglePTSD: "被思绪压倒",
    .struggleOCD: "反复的想法",
    .struggleBipolar: "情绪波动",
    .strugglePanic: "突然紧张",
    .reminderTitle: "让我们提醒您放松一下",
    .reminderSubtitle: "每天放松几分钟，已被证明可以减少38%的压力",
    .reminderMorning: "早上",
    .reminderAfternoon: "下午",
    .reminderEvening: "傍晚",
    .reminderNight: "晚上",
    .setReminder: "设置提醒",
    .lovedBy: "深受 ",
    .millions: "数百万人 喜爱",
    .unlockInfinite: "解锁无限",
    .relaxation: "放松体验",
    .reduceAnxiety: "减少焦虑，重拾专注力",
    .interactive: "互动式",
    .slimes: "史莱姆",
    .unlimited: "无限",
    .textures: "质感",
    .annualPlan: "年度 + 3天免费",
    .monthlyPlan: "月度",
    .annualPrice: "¥48 / 年",
    .monthlyPrice: "¥12 / 月",
    .annualWeekly: "¥1 / 周",
    .monthlyWeekly: "¥3 / 周",
    .discount65: "65% 折扣",
    .cancelAnytime: "随时可以取消",
    .tryForFree: "免费试用",
    .termsOfUse: "使用条款",
    .privacyPolicy: "隐私政策",
    .restore: "恢复购买",
    .premium: "高级会员！",
    .howAreYouFeeling: "您现在感觉如何？",
    .describeMood: "描述您的心情，帮助我们为您选择合适的技巧",
    .whatsOnMind: "您在想什么？",
    .letUsKnow: "告诉我们，帮助个性化您的放松课程",
    .dontWantToShare: "不想分享？点击这里开始放松",
    .todaysRelaxation: "今日放松",
    .start: "开始",
    .recommendedForYou: "为您推荐",
    .selectionsBasedOnInterests: "基于您的兴趣精选",
    .diySlimes: "DIY史莱姆",
    .kaleidoscopes: "万花筒",
    .particles: "粒子",
    .fluids: "流体",
    .moodEnergized: "充满活力",
    .moodRelaxed: "放松",
    .moodStressed: "压力",
    .moodAnxious: "焦虑",
    .moodHurt: "受伤",
    .moodSad: "悲伤",
    .moodAngry: "愤怒",
    .moodAnnoyed: "烦躁",
    .topicFamily: "家庭",
    .topicFriends: "朋友",
    .topicGames: "游戏",
    .topicSleep: "睡眠",
    .topicPets: "宠物",
    .topicRelationship: "感情",
    .topicSports: "运动",
    .topicWork: "工作",
    .categorySlimes: "史莱姆",
    .categoryDiySlimes: "DIY史莱姆",
    .categoryKaleidoscopes: "万花筒",
    .categoryParticles: "粒子",
    .categoryFluids: "流体",
    .categoryOrbs: "光球",
    .categoryFractal: "分形",
    .categoryCampfire: "篝火",
    .variantFluidsMagenta: "品红",
    .variantFluidsCyanMist: "青色薄雾",
    .variantFluidsSunsetGold: "夕阳金",
    .variantKaleidoscopePurpleCyan: "紫青",
    .variantKaleidoscopeRoseGarden: "玫瑰园",
    .variantKaleidoscopeEmerald: "翡翠",
    .variantOrbsWarmSunset: "暖日落",
    .variantOrbsDeepOcean: "深海",
    .variantOrbsAurora: "极光",
    .variantParticlesSparkle: "闪耀",
    .variantParticlesFireflies: "萤火虫",
    .variantParticlesEmberRain: "余烬雨",
    .variantSlimePastel: "粉彩",
    .variantSlimeMint: "薄荷",
    .variantSlimeBubblegum: "泡泡糖",
    .variantSlimeFur: "毛皮",
    .variantSlimeWeave: "编织",
    .variantSlimeVelvet: "天鹅绒",
    .variantSlimeMetalMesh: "金属网",
    .variantSlimeWool: "羊毛",
    .variantSlimeTeddy: "泰迪",
    .variantSlimeFrosty: "霜冻",
    .variantWavesDeepBlue: "深蓝",
    .variantWavesTropical: "热带",
    .variantWavesMoonlight: "月光",
    .breatheIn: "吸气",
    .hold: "屏住",
    .breatheOut: "呼气",
    .stop: "停止",
    .sleepStories: "睡眠故事",
    .soundRain: "雨声",
    .soundOceanWaves: "海浪声",
    .soundThunder: "雷声",
    .soundForest: "森林",
    .soundCampfire: "篝火",
    .soundWhiteNoise: "白噪音",
    .nagiUser: "Nagi用户",
    .profilePremium: "高级会员",
    .profileFree: "免费",
    .notifications: "通知",
    .vibration: "振动",
    .sound: "声音",
    .manageSubscription: "管理订阅",
    .restorePurchases: "恢复购买",
    .termsOfUseProfile: "使用条款",
    .privacyPolicyProfile: "隐私政策",
    .language: "语言",
    .settings: "设置",
    .subscription: "订阅",
    .about: "关于",
    .meditations: "冥想",
    .meditationsSubtitle: "心灵平静的音频冥想",
    .embracingLove: "拥抱爱",
    .soothingAnxiety: "舒缓焦虑",
    .hopeAndHealing: "希望与治愈",
    .yourFavorite: "你的收藏",
    .yourFavoriteSubtitle: "你喜欢的内容",
    .noFavoritesYet: "还没有收藏",
    .explore: "探索",
    .forBetterSleeping: "助你好眠",
    .forBetterSleepingSubtitle: "睡眠声音合集",
    .relaxMixes: "放松混音",
    .whiteNoiseSlimes: "白噪音史莱姆",
    .moodDiary: "心情日记",
    .moodDiaryQuestion: "今天心情怎么样？",
    .checkMyMood: "查看心情",
    .relaxHeaderSubtitle: "舒缓触感与声音体验",
    .chooseVariant: "选择质感"
]

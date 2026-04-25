import SwiftUI

final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("isSubscribed") var isSubscribed = false

    // Onboarding answers
    @Published var selectedPurpose: String?
    @Published var selectedTextures: [String] = []
    @Published var selectedSounds: [String] = []
    @Published var wantsBreathing = false
    @Published var selectedVibration: VibrationMode = .medium
    @Published var selectedStruggles: [String] = []
    @Published var reminderTime: ReminderTime?

    // Daily mood check
    @Published var todayMood: Mood?
    @Published var todayMindTopic: MindTopic?
    @Published var hasCompletedDailyCheck = false
}

enum VibrationMode: String, CaseIterable {
    case soft = "Soft"
    case medium = "Medium"
    case hard = "Hard"
    case off = "Off"

    var displayName: String {
        let l10n = LocalizationManager.shared
        switch self {
        case .soft: return l10n.string(.vibrationSoft)
        case .medium: return l10n.string(.vibrationMedium)
        case .hard: return l10n.string(.vibrationHard)
        case .off: return l10n.string(.vibrationOff)
        }
    }
}

enum ReminderTime: String, CaseIterable {
    case morning = "In the morning"
    case afternoon = "In the afternoon"
    case evening = "In the evening"
    case night = "At night"

    var displayName: String {
        let l10n = LocalizationManager.shared
        switch self {
        case .morning: return l10n.string(.reminderMorning)
        case .afternoon: return l10n.string(.reminderAfternoon)
        case .evening: return l10n.string(.reminderEvening)
        case .night: return l10n.string(.reminderNight)
        }
    }
}

enum Mood: String, CaseIterable {
    case energized = "Energized"
    case relaxed = "Relaxed"
    case stressed = "Stressed"
    case anxious = "Anxious"
    case hurt = "Hurt"
    case sad = "Sad"
    case angry = "Angry"
    case annoyed = "Annoyed"

    var displayName: String {
        let l10n = LocalizationManager.shared
        switch self {
        case .energized: return l10n.string(.moodEnergized)
        case .relaxed: return l10n.string(.moodRelaxed)
        case .stressed: return l10n.string(.moodStressed)
        case .anxious: return l10n.string(.moodAnxious)
        case .hurt: return l10n.string(.moodHurt)
        case .sad: return l10n.string(.moodSad)
        case .angry: return l10n.string(.moodAngry)
        case .annoyed: return l10n.string(.moodAnnoyed)
        }
    }

    var emoji: String {
        switch self {
        case .energized: return "😊"
        case .relaxed: return "😌"
        case .stressed: return "😟"
        case .anxious: return "😰"
        case .hurt: return "😢"
        case .sad: return "😞"
        case .angry: return "😠"
        case .annoyed: return "😤"
        }
    }
}

enum MindTopic: String, CaseIterable {
    case family = "Family"
    case friends = "Friends"
    case games = "Games"
    case sleep = "Sleep"
    case pets = "Pets"
    case relationship = "Relationship"
    case sports = "Sports"
    case work = "Work"

    var displayName: String {
        let l10n = LocalizationManager.shared
        switch self {
        case .family: return l10n.string(.topicFamily)
        case .friends: return l10n.string(.topicFriends)
        case .games: return l10n.string(.topicGames)
        case .sleep: return l10n.string(.topicSleep)
        case .pets: return l10n.string(.topicPets)
        case .relationship: return l10n.string(.topicRelationship)
        case .sports: return l10n.string(.topicSports)
        case .work: return l10n.string(.topicWork)
        }
    }

    var icon: String {
        switch self {
        case .family: return "house.fill"
        case .friends: return "person.2.fill"
        case .games: return "gamecontroller.fill"
        case .sleep: return "moon.zzz.fill"
        case .pets: return "pawprint.fill"
        case .relationship: return "heart.fill"
        case .sports: return "sportscourt.fill"
        case .work: return "briefcase.fill"
        }
    }
}

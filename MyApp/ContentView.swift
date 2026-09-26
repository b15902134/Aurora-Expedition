import SwiftUI
import Observation
import AVFoundation
import AudioToolbox
import UIKit

enum SarasateTrack: String, CaseIterable, Identifiable, Equatable {
    case romanzaAndaluza = "Pablo de Sarasate - Romanza Andaluza, Op. 22 No. 1"
    case capriceBasque = "Pablo de Sarasate - Caprice Basque, Op. 24"
    case introductionTarantella = "Pablo de Sarasate - Introduction and Tarantella"
    case zapateado = "Pablo de Sarasate - Zapateado"
    case airsEspagnols = "Pablo de Sarasate - Airs Espagnols, Op. 18"
    case laChasse = "Pablo de Sarasate - La chasse"
    case romanceSansParoles = "Henryk Wieniawski - Romance sans Paroles and Rondo élégant, Op. 9"
    case jotaAragonesa = "Pablo de Sarasate - Jota Aragonesa, Op. 27"

    var id: String { rawValue }

    var resourceName: String {
        switch self {
        case .romanzaAndaluza:
            return "Sarasate, Pablo de Spanish Dances op.22 no.1 Romanza Andaluza_320k"
        case .capriceBasque:
            return "Sarasate_ Caprice Basque, Op. 24_320k"
        case .introductionTarantella:
            return "Sarasate - Introduction and Tarantella_320k"
        case .zapateado:
            return "Sarasate - Zapateado_320k"
        case .airsEspagnols:
            return "Sarasate - Airs Espagnols (Spanish Tunes), Op. 18 in A Minor (Sheet Music)_320k"
        case .laChasse:
            return "Sarasate - La chasse_128k"
        case .romanceSansParoles:
            return "Wieniawski, Henryk  Romance sans Paroles et Rondo elegant op. 9 for violin + piano_320k"
        case .jotaAragonesa:
            return "Sarasate - Jota Aragonesa (Aragonese Jota), Op. 27 in D Major (Sheet Music)_320k"
        }
    }

    var fileExtension: String {
        self == .laChasse ? "m4a" : "mp3"
    }
}

enum GameSoundEffect: Equatable {
    case tap
    case gachaSuper
    case achievementClaim
    case battleStart
    case battleSuccess
    case battleFailure
    case upgrade
    case reward
    case warning
    case playerImpact
    case jump

    var systemSoundID: SystemSoundID {
        switch self {
        case .tap: return 1104
        case .gachaSuper: return 1025
        case .achievementClaim: return 1025
        case .battleStart: return 1054
        case .battleSuccess, .upgrade, .reward: return 1057
        case .battleFailure: return 1053
        case .warning: return 1073
        case .playerImpact: return 1004
        case .jump: return 1103
        }
    }
}

@MainActor
@Observable
final class AudioManager: NSObject, AVAudioPlayerDelegate {
    var selectedTrack: SarasateTrack = .romanzaAndaluza
    var isMuted = false
    var musicVolume: Float = 0.38
    var lastCompletedTrack: SarasateTrack?

    @ObservationIgnored private var musicPlayer: AVAudioPlayer?

    func startMusic() {
        musicPlayer?.stop()
        guard !isMuted else { return }

        let bundleURL = Bundle.main.url(
            forResource: selectedTrack.resourceName,
            withExtension: selectedTrack.fileExtension
        ) ?? Bundle.main.url(
            forResource: selectedTrack.resourceName,
            withExtension: selectedTrack.fileExtension,
            subdirectory: "Audio"
        )

        #if DEBUG && os(macOS)
        let projectAudioURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Audio")
            .appendingPathComponent("\(selectedTrack.resourceName).\(selectedTrack.fileExtension)")
        let url = bundleURL ?? (FileManager.default.fileExists(atPath: projectAudioURL.path) ? projectAudioURL : nil)
        #else
        let url = bundleURL
        #endif

        guard let url else {
            return
        }

        #if os(iOS) || os(tvOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.numberOfLoops = 0
            player.volume = musicVolume
            player.prepareToPlay()
            player.play()
            musicPlayer = player
        } catch {
            musicPlayer = nil
        }
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            musicPlayer?.pause()
        } else if musicPlayer == nil {
            startMusic()
        } else {
            musicPlayer?.play()
        }
    }

    func selectTrack(_ track: SarasateTrack) {
        selectedTrack = track
        startMusic()
    }

    func playEffect(_ effect: GameSoundEffect) {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(effect.systemSoundID)
    }

    func playGachaSuperEffect() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(GameSoundEffect.gachaSuper.systemSoundID)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 140_000_000)
            guard !isMuted else { return }
            AudioServicesPlaySystemSound(1057)

            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !isMuted else { return }
            AudioServicesPlaySystemSound(1025)
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag, !isMuted else { return }

        lastCompletedTrack = selectedTrack
        let tracks = SarasateTrack.allCases
        let currentIndex = tracks.firstIndex(of: selectedTrack) ?? 0
        selectedTrack = tracks[(currentIndex + 1) % tracks.count]
        startMusic()
    }
}


enum GearSlot: String, CaseIterable, Identifiable, Codable {
    case helmet = "Helmet"
    case mac = "Mac"
    case sunglasses = "Sunglasses"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .helmet: return "helmet.fill"
        case .mac: return "laptopcomputer"
        case .sunglasses: return "eyeglasses"
        }
    }

    var accent: Color {
        switch self {
        case .helmet: return .pink
        case .mac: return .cyan
        case .sunglasses: return .orange
        }
    }
}

enum StatType: String, CaseIterable, Identifiable, Codable {
    case attack = "Attack"
    case health = "Health"
    case critRate = "Crit Rate"
    case critDamage = "Crit Damage"

    var id: String { rawValue }
}

struct StatLine: Identifiable, Codable {
    let id: UUID
    var type: StatType
    var value: Double

    init(id: UUID = UUID(), type: StatType, value: Double) {
        self.id = id
        self.type = type
        self.value = value
    }

    var displayValue: String {
        "+\(value.formatted(.number.precision(.fractionLength(1))))%"
    }
}

struct ResourceShortage: Identifiable {
    let id = UUID()
    let resourceName: String
    let required: Int
    let current: Int
    let actionName: String

    var missing: Int {
        max(0, required - current)
    }
}

enum SkillKind: String, CaseIterable, Identifiable {
    case controlImmunity = "Frostwall Will"
    case negativeAttack = "Aurora Curse"
    case regeneration = "Life Flow"
    case rapidFire = "Double Pulse"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .controlImmunity: return "shield.lefthalf.filled"
        case .negativeAttack: return "exclamationmark.triangle.fill"
        case .regeneration: return "heart.fill"
        case .rapidFire: return "bolt.horizontal.fill"
        }
    }

    var detail: String {
        switch self {
        case .controlImmunity: return "Immune to Freeze and control effects for a short time"
        case .negativeAttack: return "Mac hits apply a debuff for a short time"
        case .regeneration: return "Regenerate Health for a short time"
        case .rapidFire: return "Double Mac throw rate for a short time"
        }
    }
}

struct SkillCard: Identifiable {
    let id = UUID()
    let kind: SkillKind
    var level = 1

    var duration: Int {
        4 + level
    }

    var intensity: Double {
        1 + Double(level - 1) * 0.2
    }

    var upgradeCost: Int {
        level * 2
    }
}

struct Gear: Identifiable, Codable {
    let id: UUID
    var slot: GearSlot
    var stars: Int
    var level: Int
    var style: String
    var mainStat: StatLine
    var subStats: [StatLine]

    init(
        id: UUID = UUID(),
        slot: GearSlot,
        stars: Int,
        level: Int,
        style: String = "Standard",
        mainStat: StatLine,
        subStats: [StatLine]
    ) {
        self.id = id
        self.slot = slot
        self.stars = stars
        self.level = level
        self.style = style
        self.mainStat = mainStat
        self.subStats = subStats
    }

    var displayName: String {
        "\(stars)-Star · \(style)"
    }

    var rarityColor: Color {
        switch stars {
        case 7: return .yellow
        case 5: return .purple
        case 3: return .blue
        default: return .gray
        }
    }

    var maxLevel: Int {
        stars * 5
    }

    var upgradeCost: Int {
        300 + (level * level * stars * 12)
    }
}

struct AccountTransferPayload: Codable {
    var characterName: String
    var playerLevel: Int
    var gold: Int
    var gems: Int
    var fish: Int
    var pity: Int
    var totalPulls: Int
    var gear: [Gear]
    var equippedGearIDs: [GearSlot: UUID]
}

@MainActor
@Observable
final class GameStore {
    var characterName: String {
        didSet {
            UserDefaults.standard.set(characterName, forKey: "characterName")
        }
    }

    var gold = 10_000
    var gems = 1_600
    var fish = 0
    var playerLevel = 1
    var baseAttack = 164
    var baseHealth = 1_250
    var baseCritRate = 0.0
    var baseCritDamage = 100.0
    var pity = 0
    var totalPulls = 0
    var defeatedEnemies = 0
    var fishCaught = 0
    var message = "A new journey begins across the frozen north."
    var pendingSoundEffect: GameSoundEffect?
    var pendingAchievementCompletion: String?
    var completedMusicTracks: Set<String> = []
    var resourceShortage: ResourceShortage?
    var lastPulledGear: Gear?
    var lastPulledGears: [Gear] = []
    var claimedAchievements: Set<String> = []
    var announcedAchievements: Set<String> = []
    var equippedGearIDs: [GearSlot: UUID] = [:]
    var skillPoints = 6
    var skillSlotCount: Int {
        didSet {
            UserDefaults.standard.set(skillSlotCount, forKey: "skillSlotCount")
        }
    }
    var skills: [SkillCard] = SkillKind.allCases.map { SkillCard(kind: $0) }
    var lastPulledSkills: [SkillCard] = []
    var equippedSkillIDs: [UUID] = []

    var equippedSkills: [SkillCard] {
        equippedSkillIDs.compactMap { id in
            skills.first(where: { $0.id == id })
        }
    }

    var gear: [Gear] = [
        Gear(
            slot: .helmet,
            stars: 1,
            level: 1,
            style: "Starter Polar Helmet",
            mainStat: StatLine(type: .health, value: 3),
            subStats: [StatLine(type: .health, value: 2)]
        ),
        Gear(
            slot: .mac,
            stars: 1,
            level: 1,
            style: "Starter Mac",
            mainStat: StatLine(type: .health, value: 3),
            subStats: [StatLine(type: .health, value: 2)]
        ),
        Gear(
            slot: .sunglasses,
            stars: 1,
            level: 1,
            style: "Starter Aurora Sunglasses",
            mainStat: StatLine(type: .health, value: 3),
            subStats: [StatLine(type: .health, value: 2)]
        )
    ]

    init() {
        let savedCharacterName = UserDefaults.standard.string(forKey: "characterName")
        let initialCharacterName = savedCharacterName == "阿蒙森" || savedCharacterName == "冒險者" ? "Adventurer" : savedCharacterName ?? "Adventurer"
        characterName = initialCharacterName
        UserDefaults.standard.set(initialCharacterName, forKey: "characterName")
        skillSlotCount = max(1, UserDefaults.standard.integer(forKey: "skillSlotCount"))
        for item in gear {
            equippedGearIDs[item.slot] = item.id
        }
        equippedSkillIDs = [skills[0].id]
    }

    func drawSkillCard() {
        drawSkillCards(count: 1)
    }

    func drawSkillCards(count: Int) {
        let pullCount = max(1, count)
        let totalCost = pullCount * 200

        guard gems >= totalCost else {
            lastPulledSkills = []
            message = "Not enough Gems. The Skill Pool requires \(totalCost) Gems."
            return
        }

        gems -= totalCost
        let results = (0..<pullCount).map { _ in
            SkillCard(kind: SkillKind.allCases.randomElement() ?? .controlImmunity)
        }
        skills.append(contentsOf: results)
        lastPulledSkills = results
        message = pullCount == 10
            ? "Ten Skill Summons complete. Received 10 Skill Cards."
            : "Pulled Skill Card \(results[0].kind.rawValue): \(results[0].kind.detail)."
    }

    func equipSkill(_ skill: SkillCard) {
        guard !equippedSkillIDs.contains(skill.id) else {
            equippedSkillIDs.removeAll { $0 == skill.id }
            message = "Unequipped Skill \(skill.kind.rawValue)."
            return
        }

        guard equippedSkillIDs.count < skillSlotCount else {
            message = "Skill slots are full. Unequip a skill or unlock the second slot first."
            return
        }

        equippedSkillIDs.append(skill.id)
        message = "Equipped Skill \(skill.kind.rawValue)."
    }

    func upgradeSkill(_ skill: SkillCard) {
        guard let index = skills.firstIndex(where: { $0.id == skill.id }) else { return }
        let cost = skills[index].upgradeCost
        guard skillPoints >= cost else {
            message = "Not enough Skill Points. Upgrade requires \(cost) Skill Points."
            return
        }

        skillPoints -= cost
        skills[index].level += 1
        message = "\(skills[index].kind.rawValue) reached Lv.\(skills[index].level). Duration and effect strength increased."
    }

    func purchaseSkillSlot() {
        guard skillSlotCount < 2 else {
            message = "The second Skill Slot is already unlocked."
            return
        }

        // 先以商店中的課金商品入口模擬購買，之後可替換成 StoreKit 交易。
        skillSlotCount = 2
        message = "Premium unlock applied: Second Skill Slot."
    }

    func destroy(_ item: Gear) {
        guard gear.contains(where: { $0.id == item.id }) else { return }

        guard equippedGearIDs[item.slot] != item.id else {
            message = "Equipped gear cannot be dismantled. Equip another item first."
            return
        }

        let sameSlotCount = gear.filter { $0.slot == item.slot }.count
        guard sameSlotCount > 1 else {
            message = "Keep at least one \(item.slot.rawValue) item. It cannot be dismantled."
            return
        }

        let reward = item.stars * 1_000
        gear.removeAll { $0.id == item.id }

        if equippedGearIDs[item.slot] == item.id {
            equippedGearIDs[item.slot] = nil
        }

        gold += reward
        message = "Dismantled \(item.displayName) and received \(reward.formatted()) Gold."
    }

    func pullCard() {
        lastPulledGear = nil
        lastPulledGears = []

        guard gems >= 160 else {
            resourceShortage = ResourceShortage(
                resourceName: "Gems",
                required: 160,
                current: gems,
                actionName: "Single Summon"
            )
            message = "Not enough Gems. Need \(max(0, 160 - gems).formatted()) more."
            return
        }

        resourceShortage = nil

        gems -= 160
        totalPulls += 1
        pity += 1

        let softPityBonus = max(0, pity - 69)
        let sevenStarChance = min(0.006 + Double(softPityBonus) * 0.02, 0.5)
        let isSevenStar = pity >= 80 || Double.random(in: 0...1) < sevenStarChance

        let rarity: Int
        if isSevenStar {
            rarity = 7
            pity = 0
        } else {
            let rarityRoll = Double.random(in: 0...1)
            rarity = rarityRoll < 0.18 ? 5 : rarityRoll < 0.65 ? 3 : 1
        }

        let subStatCount = min(4, max(1, rarity - 2))
        let selectedStats = Array(StatType.allCases.shuffled().prefix(subStatCount))
        let newSlot = GearSlot.allCases.randomElement() ?? .mac
        let styleNames: [GearSlot: [String]] = [
            .helmet: ["Aurora Helmet", "Ice Crystal Helmet", "Frostland Helmet"],
            .mac: ["Frost Moon Mac", "Polar Mac", "Stardust Mac"],
            .sunglasses: ["Aurora Sunglasses", "Ice Crystal Sunglasses", "Frostland Sunglasses"]
        ]
        let newGear = Gear(
            slot: newSlot,
            stars: rarity,
            level: 1,
            style: styleNames[newSlot]?.randomElement() ?? "Standard",
            mainStat: StatLine(
                type: StatType.allCases.randomElement() ?? .attack,
                value: Double(rarity * 5) + Double.random(in: 0...4)
            ),
            subStats: selectedStats.map { stat in
                StatLine(type: stat, value: Double(rarity * 2) + Double.random(in: 0...5))
            }
        )

        gear.append(newGear)
        lastPulledGear = newGear
        lastPulledGears = [newGear]
        message = rarity == 7
            ? "✨ Pulled 7-Star \(newGear.slot.rawValue)! All four substats unlocked."
            : "Pulled \(rarity)-Star \(newGear.slot.rawValue). Equip it from the Character Profile. \(max(0, 80 - pity)) pulls until 7-Star pity."
        checkAchievementCompletions()
    }

    func equip(_ item: Gear) {
        equippedGearIDs[item.slot] = item.id
        message = "Equipped \(item.displayName) (\(item.slot.rawValue))."
        checkAchievementCompletions()
    }

    func equippedItem(for slot: GearSlot) -> Gear? {
        guard let id = equippedGearIDs[slot] else {
            return nil
        }
        return gear.first(where: { $0.id == id })
    }

    func pullTenCards() {
        guard gems >= 1_600 else {
            resourceShortage = ResourceShortage(
                resourceName: "Gems",
                required: 1_600,
                current: gems,
                actionName: "Ten Summons"
            )
            message = "Not enough Gems. Need \(max(0, 1_600 - gems).formatted()) more."
            return
        }

        resourceShortage = nil
        var results: [Gear] = []
        for _ in 0..<10 {
            pullCard()
            if let result = lastPulledGear {
                results.append(result)
            }
        }

        if let bestResult = results.max(by: { $0.stars < $1.stars }) {
            lastPulledGear = bestResult
            lastPulledGears = results
            let starSummary = results.map { "\($0.stars)★" }.joined(separator: ", ")
            message = "Ten Summons complete: \(starSummary). Highest rarity: \(bestResult.stars)-Star."
        }
    }

    func upgrade(_ item: Gear) {
        guard let index = gear.firstIndex(where: { $0.id == item.id }) else { return }

        let cost = gear[index].upgradeCost
        guard gear[index].level < gear[index].maxLevel else {
            pendingSoundEffect = .warning
            message = "\(gear[index].displayName) has reached max level: Lv.\(gear[index].maxLevel)."
            return
        }

        guard gold >= cost else {
            resourceShortage = ResourceShortage(
                resourceName: "Gold",
                required: cost,
                current: gold,
                actionName: "Upgrade Equipment"
            )
            pendingSoundEffect = .warning
            message = "Not enough Gold. Need \(max(0, cost - gold).formatted()) more."
            return
        }

        resourceShortage = nil
        pendingSoundEffect = .upgrade

        gold -= cost
        gear[index].level += 1
        gear[index].mainStat.value += Double(gear[index].stars) * 1.5

        if gear[index].level % 5 == 0, gear[index].subStats.count < 4 {
            let existingTypes = Set(gear[index].subStats.map(\.type))
            let candidates = StatType.allCases.filter { !existingTypes.contains($0) }
            if let newType = candidates.randomElement() {
                gear[index].subStats.append(
                    StatLine(type: newType, value: Double(gear[index].stars) * 2)
                )
                message = "\(gear[index].displayName) reached Lv.\(gear[index].level). Main stat increased and a new substat unlocked. Spent \(cost.formatted()) Gold."
                return
            }
        }

        message = "\(gear[index].displayName) reached Lv.\(gear[index].level). Main stat increased. Spent \(cost.formatted()) Gold."
    }

    var characterUpgradeCost: Int {
        8 + playerLevel * 4
    }

    func upgradeCharacter() {
        let cost = characterUpgradeCost
        guard fish >= cost else {
            resourceShortage = ResourceShortage(
                resourceName: "Fish",
                required: cost,
                current: fish,
                actionName: "Upgrade Character"
            )
            pendingSoundEffect = .warning
            message = "Not enough Fish. Need \(max(0, cost - fish).formatted()) more."
            return
        }

        resourceShortage = nil
        pendingSoundEffect = .upgrade

        fish -= cost
        playerLevel += 1
        baseAttack += 12
        baseHealth += 90
        message = "\(characterName) reached Lv.\(playerLevel): Attack +12, Health +90. Spent \(cost.formatted()) Fish."
        checkAchievementCompletions()
    }

    func purchaseStarterPack() {
        gold += 1_000_000
        gems += 88_888
        fish += 1_000
        fishCaught += 1_000
        message = "Starter Bundle received: 1,000,000 Gold, 88,888 Gems, and 1,000 Fish."
        checkAchievementCompletions()
    }

    func purchaseGoldPack() {
        gold += 100_000
        message = "Gold Bundle received: +100,000 Gold."
    }

    func purchaseGemPack() {
        gems += 1_600
        message = "Gem Bundle received: +1,600 Gems."
    }

    func purchaseFishPack() {
        fish += 100
        fishCaught += 100
        message = "Fish Bundle received: +100 Fish."
        checkAchievementCompletions()
    }

    func purchaseSkillPointPack() {
        skillPoints += 10
        message = "Skill Point Bundle received: +10 Skill Points."
    }

    func equipmentBonus(for stat: StatType) -> Double {
        GearSlot.allCases
            .compactMap { equippedItem(for: $0) }
            .flatMap { [$0.mainStat] + $0.subStats }
            .filter { $0.type == stat }
            .reduce(0) { $0 + $1.value }
    }

    var finalAttack: Int {
        Int(Double(baseAttack) * (1 + equipmentBonus(for: .attack) / 100))
    }

    var finalHealth: Int {
        Int(Double(baseHealth) * (1 + equipmentBonus(for: .health) / 100))
    }

    var finalCritRate: Double {
        baseCritRate + equipmentBonus(for: .critRate)
    }

    var finalCritDamage: Double {
        let directCritDamage = baseCritDamage + equipmentBonus(for: .critDamage)
        let overcapCritRate = max(0, finalCritRate - 100)
        // 暴擊率超過 100% 後，每 1% 轉換成 2% 爆擊傷害。
        return directCritDamage + overcapCritRate * 2
    }

    var combatPower: Int {
        let equippedItems = GearSlot.allCases.compactMap { equippedItem(for: $0) }
        let equipmentLevelScore = equippedItems.reduce(0) { $0 + ($1.level * 6) }
        let equipmentRarityScore = equippedItems.reduce(0) { $0 + ($1.stars * $1.stars * 12) }

        let baseScore =
            Double(finalAttack) * 1.4 +
            Double(finalHealth) * 0.16 +
            finalCritRate * 9 +
            finalCritDamage * 2.2

        return Int(baseScore) + equipmentLevelScore + equipmentRarityScore
    }

    private func achievementTitle(for id: String) -> String {
        switch id {
        case "firstBattle": return "First Frost"
        case "iceHunter": return "Ice Lake Hunter"
        case "auroraSummoner": return "Aurora Summoner"
        case "snowCleaner": return "Snowfield Cleaner"
        case "musicRomanzaAndaluza": return "Voice of Andalusia"
        case "musicCapriceBasque": return "Basque String Connoisseur"
        case "musicIntroductionTarantella": return "Tarantella Flame Listener"
        case "musicZapateado": return "Zapateado Dance King"
        case "musicAirsEspagnols": return "Spanish Tunes Listener"
        case "musicLaChasse": return "La chasse Listener"
        case "musicRomanceSansParoles": return "Romance Listener"
        case "musicJotaAragonesa": return "Jota Aragonesa Listener"
        case "levelFive": return "Frostland Awakening"
        case "levelTen": return "Polar Overlord"
        case "seasonedAngler": return "Abyss Angler"
        case "masterAngler": return "Ice Lake Dragon King"
        case "firstTenPulls": return "First Aurora Summon"
        case "summonCollector": return "Summon Collector"
        case "battleVeteran": return "Frostfang Veteran"
        case "battleMaster": return "Battlefield Tyrant"
        case "gearCollector": return "Legendary Gear Collector"
        case "legendaryHunter": return "Seven-Star Chosen"
        case "completeLoadout": return "Fully Armed Frost Fox"
        default: return "New Achievement"
        }
    }

    private func musicAchievementID(for track: SarasateTrack) -> String {
        switch track {
        case .romanzaAndaluza: return "musicRomanzaAndaluza"
        case .capriceBasque: return "musicCapriceBasque"
        case .introductionTarantella: return "musicIntroductionTarantella"
        case .zapateado: return "musicZapateado"
        case .airsEspagnols: return "musicAirsEspagnols"
        case .laChasse: return "musicLaChasse"
        case .romanceSansParoles: return "musicRomanceSansParoles"
        case .jotaAragonesa: return "musicJotaAragonesa"
        }
    }

    func claimAchievement(id: String, progress: Int, total: Int, reward: Int) {
        guard progress >= total, !claimedAchievements.contains(id) else {
            pendingSoundEffect = .warning
            return
        }
        claimedAchievements.insert(id)
        gems += reward
        pendingSoundEffect = .achievementClaim
        message = "Claimed \(achievementTitle(for: id)) reward: \(reward) Gems."
    }

    private func checkAchievementCompletions() {
        let achievements: [(String, Bool)] = [
            ("firstBattle", defeatedEnemies >= 1),
            ("musicRomanzaAndaluza", completedMusicTracks.contains(SarasateTrack.romanzaAndaluza.id)),
            ("musicCapriceBasque", completedMusicTracks.contains(SarasateTrack.capriceBasque.id)),
            ("musicIntroductionTarantella", completedMusicTracks.contains(SarasateTrack.introductionTarantella.id)),
            ("musicZapateado", completedMusicTracks.contains(SarasateTrack.zapateado.id)),
            ("musicAirsEspagnols", completedMusicTracks.contains(SarasateTrack.airsEspagnols.id)),
            ("musicLaChasse", completedMusicTracks.contains(SarasateTrack.laChasse.id)),
            ("musicRomanceSansParoles", completedMusicTracks.contains(SarasateTrack.romanceSansParoles.id)),
            ("musicJotaAragonesa", completedMusicTracks.contains(SarasateTrack.jotaAragonesa.id)),
            ("iceHunter", fishCaught >= 100),
            ("auroraSummoner", totalPulls >= 200),
            ("snowCleaner", defeatedEnemies >= 100),
            ("levelFive", playerLevel >= 5),
            ("levelTen", playerLevel >= 10),
            ("seasonedAngler", fishCaught >= 500),
            ("masterAngler", fishCaught >= 1_000),
            ("firstTenPulls", totalPulls >= 10),
            ("summonCollector", totalPulls >= 50),
            ("battleVeteran", defeatedEnemies >= 10),
            ("battleMaster", defeatedEnemies >= 500),
            ("gearCollector", gear.count >= 10),
            ("legendaryHunter", gear.contains { $0.stars == 7 }),
            ("completeLoadout", GearSlot.allCases.allSatisfy { equippedItem(for: $0) != nil })
        ]

        guard let newlyCompleted = achievements.first(where: {
            $0.1 && !claimedAchievements.contains($0.0) && !announcedAchievements.contains($0.0)
        }) else { return }

        announcedAchievements.insert(newlyCompleted.0)
        pendingSoundEffect = .achievementClaim
        pendingAchievementCompletion = achievementTitle(for: newlyCompleted.0)
        message = "Achievement complete: \(achievementTitle(for: newlyCompleted.0)). You can claim the reward now."
    }

    func registerMusicTrackCompleted(_ track: SarasateTrack) {
        guard completedMusicTracks.insert(track.id).inserted else { return }

        message = "Finished \(track.rawValue). Music achievement complete—claim 16,000 Gems from Achievements."
        checkAchievementCompletions()
    }

    func claimAllAchievements() {
        let achievements: [(String, Bool, Int)] = [
            ("firstBattle", defeatedEnemies >= 1, 50),
            ("musicRomanzaAndaluza", completedMusicTracks.contains(SarasateTrack.romanzaAndaluza.id), 16_000),
            ("musicCapriceBasque", completedMusicTracks.contains(SarasateTrack.capriceBasque.id), 16_000),
            ("musicIntroductionTarantella", completedMusicTracks.contains(SarasateTrack.introductionTarantella.id), 16_000),
            ("musicZapateado", completedMusicTracks.contains(SarasateTrack.zapateado.id), 16_000),
            ("musicAirsEspagnols", completedMusicTracks.contains(SarasateTrack.airsEspagnols.id), 16_000),
            ("musicLaChasse", completedMusicTracks.contains(SarasateTrack.laChasse.id), 16_000),
            ("musicRomanceSansParoles", completedMusicTracks.contains(SarasateTrack.romanceSansParoles.id), 16_000),
            ("iceHunter", fishCaught >= 100, 100),
            ("auroraSummoner", totalPulls >= 200, 200),
            ("snowCleaner", defeatedEnemies >= 100, 150),
            ("levelFive", playerLevel >= 5, 100),
            ("levelTen", playerLevel >= 10, 250),
            ("seasonedAngler", fishCaught >= 500, 300),
            ("masterAngler", fishCaught >= 1_000, 600),
            ("firstTenPulls", totalPulls >= 10, 100),
            ("summonCollector", totalPulls >= 50, 300),
            ("battleVeteran", defeatedEnemies >= 10, 120),
            ("battleMaster", defeatedEnemies >= 500, 500),
            ("gearCollector", gear.count >= 10, 150),
            ("legendaryHunter", gear.contains { $0.stars == 7 }, 400),
            ("completeLoadout", GearSlot.allCases.allSatisfy { equippedItem(for: $0) != nil }, 200)
        ]
        var totalReward = 0

        for (id, isComplete, reward) in achievements where isComplete && !claimedAchievements.contains(id) {
            claimedAchievements.insert(id)
            totalReward += reward
        }

        if totalReward > 0 {
            gems += totalReward
            pendingSoundEffect = .achievementClaim
            message = "Claimed all achievement rewards: \(totalReward) Gems."
        } else {
            pendingSoundEffect = .warning
            message = "No achievement rewards are available."
        }
    }

    func fishAtLake() {
        let catchAmount = Int.random(in: 1...4)
        fish += catchAmount
        fishCaught += catchAmount
        message = "Caught \(catchAmount) Ice Crystal Fish. Feed \(characterName) to unlock passive talents."
        checkAchievementCompletions()
    }

    func enterBattle() {
        pendingSoundEffect = .battleStart
        let critRoll = Double.random(in: 0...1)
        let critMultiplier = critRoll < 0.18 ? 1.8 : 1.0
        let damage = max(1, Int(Double(baseAttack + 82) * critMultiplier - 24))
        gold += 240
        defeatedEnemies += 1
        message = critMultiplier > 1 ? "Mac spin scored a critical hit! Dealt \(damage) damage and earned 240 Gold." : "Mac throw hit for \(damage) damage and earned 240 Gold."
        checkAchievementCompletions()
    }

    func makeTransferCode() -> String {
        let payload = AccountTransferPayload(
            characterName: characterName,
            playerLevel: playerLevel,
            gold: gold,
            gems: gems,
            fish: fish,
            pity: pity,
            totalPulls: totalPulls,
            gear: gear,
            equippedGearIDs: equippedGearIDs
        )
        guard let data = try? JSONEncoder().encode(payload) else { return "" }
        return data.base64EncodedString()
    }

    func inheritAccount(from code: String) -> Bool {
        let normalizedCode = code.replacingOccurrences(of: " ", with: "")
        guard let data = Data(base64Encoded: normalizedCode),
              let payload = try? JSONDecoder().decode(AccountTransferPayload.self, from: data),
              !payload.characterName.isEmpty else {
            return false
        }

        characterName = String(payload.characterName.prefix(20))
        playerLevel = max(1, payload.playerLevel)
        gold = max(0, payload.gold)
        gems = max(0, payload.gems)
        fish = max(0, payload.fish)
        pity = max(0, min(79, payload.pity))
        totalPulls = max(0, payload.totalPulls)
        if !payload.gear.isEmpty {
            gear = payload.gear
            equippedGearIDs = payload.equippedGearIDs
        }
        message = "Account transfer complete: \(characterName)."
        return true
    }
}

enum MinefieldMode {
    case dig
    case flag
}

enum HomeHero: CaseIterable {
    case blue
    case yellow
    case red
    case purple

    var imageName: String {
        switch self {
        case .blue: return "HomeHeroBlue"
        case .yellow: return "HomeHeroYellow"
        case .red: return "HomeHeroRed"
        case .purple: return "HomeHeroPurple"
        }
    }

    var accent: Color {
        switch self {
        case .blue: return Color(red: 0.39, green: 0.69, blue: 0.96)
        case .yellow: return Color(red: 1.0, green: 0.78, blue: 0.27)
        case .red: return Color(red: 0.94, green: 0.31, blue: 0.35)
        case .purple: return Color(red: 0.66, green: 0.45, blue: 0.94)
        }
    }

    func shifted(by offset: Int) -> HomeHero {
        let choices = Self.allCases
        let currentIndex = choices.firstIndex(of: self) ?? 0
        let nextIndex = (currentIndex + offset + choices.count) % choices.count
        return choices[nextIndex]
    }
}

enum GameSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case equipment = "Equipment"
    case profile = "Profile"
    case gacha = "Summon"
    case fishing = "Fishing"
    case achievements = "Achievements"
    case backpack = "Backpack"
    case leaderboard = "Leaderboard"
    case store = "Store"

    var id: Self { self }

    var title: String { rawValue }

    var subtitle: String {
        switch self {
        case .overview: return "Polar Expedition Base"
        case .equipment: return "Upgrade and manage combat equipment"
        case .profile: return "Character stats and equipment loadout"
        case .gacha: return "Summon equipment and skill cards"
        case .fishing: return "Explore the ice lake and gather resources"
        case .achievements: return "Track progress and claim rewards"
        case .backpack: return "Manage collected materials and equipment"
        case .leaderboard: return "Compare expedition combat performance"
        case .store: return "Get resources for your expedition"
        }
    }

    var symbol: String {
        switch self {
        case .overview: return "house.fill"
        case .equipment: return "shield.fill"
        case .profile: return "person.crop.circle.fill"
        case .gacha: return "sparkles"
        case .fishing: return "fish.fill"
        case .achievements: return "trophy.fill"
        case .backpack: return "backpack.fill"
        case .leaderboard: return "chart.bar.fill"
        case .store: return "bag.fill"
        }
    }
}

struct ContentView: View {
    @State private var store = GameStore()
    @State private var audioManager = AudioManager()
    @State private var selectedSection: GameSection = .overview
    @State private var foxIsWalking = false
    @State private var showGachaReveal = false
    @State private var showSkillReveal = false
    @State private var showBattle = false
    @State private var battleLevel = 1
    @State private var showMusicList = false
    @State private var showAccountSettings = false
    @State private var selectedGearSlot: GearSlot = .helmet
    @State private var selectedProfileGearID: UUID?
    @State private var selectedBackpackSlot: GearSlot?
    @State private var leaderboardCategory = "Combat Power"
    @State private var pendingDestroy: Gear? = nil
    @State private var combatPowerGain: Int?
    @State private var achievementBanner: String?
    @State private var homeTapCount = 0
    @State private var minefieldDifficulty = 1
    @State private var minefieldSize = 7
    @State private var minefieldCells = Array(repeating: 0, count: 49)


    @State private var revealedMinefieldCells = Array(repeating: false, count: 49)
    @State private var minefieldMines = Set<Int>()
    @State private var minefieldFish = Set<Int>()
    @State private var minefieldFoundFish = 0
    @State private var flaggedMinefieldCells = Set<Int>()
    @State private var minefieldMode: MinefieldMode = .dig
    @State private var minefieldHasStarted = false
    @State private var minefieldStatus = "Choose a difficulty, then break the ice."
    @State private var minefieldFinished = false
    @State private var minefieldReward: Int?

    private let sections: [GameSection] = [.overview, .equipment, .gacha, .fishing, .achievements]

    var body: some View {
        ZStack(alignment: .bottom) {
            if showBattle {
                GeometryReader { proxy in
                    ZStack(alignment: .bottom) {
                        Image("AuroraBackground")
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                            .overlay {
                                LinearGradient(
                                    colors: [.black.opacity(0.08), .black.opacity(0.32)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }

                    }
                }
                .ignoresSafeArea()

                GeometryReader { floorProxy in
                    VStack {
                        Spacer()
                        SnowBlockPlatform()
                            .frame(width: floorProxy.size.width + 80, height: 58)
                            .padding(.bottom, 88)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

                BattleView(
                    store: store,
                    isPresented: $showBattle,
                    level: $battleLevel
                )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .zIndex(20)
            } else {
                if selectedSection == .overview {
                GeometryReader { proxy in
                    Image("AuroraBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .overlay {
                            LinearGradient(
                                colors: [
                                    .black.opacity(0.08),
                                    .black.opacity(0.32)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }
                .ignoresSafeArea()
                .zIndex(-1)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.16, blue: 0.25),
                        Color(red: 0.025, green: 0.045, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            if selectedSection == .overview {
                homeStage
                    .zIndex(1)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        SystemPageHeader(
                            section: selectedSection,
                            characterName: store.characterName,
                            level: store.playerLevel
                        )
                        selectedSystemView
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 58)
                    .padding(.bottom, 76)
                }
                .id(selectedSection)
            }

            }

            if !showBattle {
                bottomNavigation
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if !showBattle, let combatPowerGain {
                CombatPowerToast(delta: combatPowerGain)
                    .padding(.top, 72)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .overlay(alignment: .top) {
            VStack(spacing: 8) {
                if let achievementBanner {
                    AchievementCompletionBanner(title: achievementBanner)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(12)
                }

                if !showBattle {
                    HStack {
                        Spacer()
                        resourceStrip
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            audioManager.startMusic()
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                foxIsWalking = true
            }
        }
        .onChange(of: store.pendingSoundEffect) { _, effect in
            guard let effect else { return }
            audioManager.playEffect(effect)
            store.pendingSoundEffect = nil
        }
        .onChange(of: store.pendingAchievementCompletion) { _, title in
            guard let title else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                achievementBanner = title
            }
            store.pendingAchievementCompletion = nil

            Task {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
                withAnimation(.easeOut(duration: 0.25)) {
                    achievementBanner = nil
                }
            }
        }
        .onChange(of: audioManager.lastCompletedTrack) { _, track in
            guard let track else { return }
            store.registerMusicTrackCompleted(track)
            audioManager.lastCompletedTrack = nil
        }
        .onChange(of: store.combatPower) { oldValue, newValue in
            let delta = newValue - oldValue
            guard delta != 0 else { return }

            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                combatPowerGain = delta
            }

            Task {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                withAnimation(.easeOut(duration: 0.25)) {
                    combatPowerGain = nil
                }
            }
        }
        .sheet(isPresented: $showMusicList) {
            NavigationStack {
                List {
                    Section("Sarasate Tracks") {
                        ForEach(SarasateTrack.allCases) { track in
                            Button {
                                audioManager.selectTrack(track)
                                showMusicList = false
                            } label: {
                                HStack {
                                    Image(systemName: track == audioManager.selectedTrack ? "checkmark.circle.fill" : "music.note")
                                        .foregroundStyle(track == audioManager.selectedTrack ? .yellow : .cyan)
                                    Text(track.rawValue)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if track == audioManager.selectedTrack {
                                        Text("Playing")
                                            .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Background Music")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showMusicList = false
                        }
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showAccountSettings) {
            AccountSettingsView(store: store)
        }
        .sheet(isPresented: $showGachaReveal) {
            if store.lastPulledGears.count == 10 {
                GachaTenRevealView(items: store.lastPulledGears) {
                    if let best = store.lastPulledGears.max(by: { $0.stars < $1.stars }) {
                        store.equip(best)
                    }
                    showGachaReveal = false
                }
            } else if let item = store.lastPulledGear {
                GachaRevealView(item: item) {
                    store.equip(item)
                    showGachaReveal = false
                }
            }
        }
        .sheet(isPresented: $showSkillReveal) {
            SkillRevealView(items: store.lastPulledSkills) {
                showSkillReveal = false
            }
        }
        .confirmationDialog(
            "Destroy Equipment?",
            isPresented: Binding(
                get: { pendingDestroy != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDestroy = nil
                    }
                }
            ),
            presenting: pendingDestroy
        ) { item in
            Button("Destroy \(item.displayName)", role: .destructive) {
                store.destroy(item)
                pendingDestroy = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDestroy = nil
            }
        } message: { item in
            Text("Gain \(item.stars * 1_000) Gold. This cannot be undone.")
        }
        .alert(item: $store.resourceShortage) { shortage in
            Alert(
                title: Text("Insufficient Resources"),
                message: Text("\(shortage.actionName) needs \(shortage.missing.formatted()) more \(shortage.resourceName) (\(shortage.current.formatted()) / \(shortage.required.formatted()))."),
                primaryButton: .default(Text("Go to Store")) {
                    store.resourceShortage = nil
                    selectedSection = .store
                },
                secondaryButton: .cancel(Text("OK")) {
                    store.resourceShortage = nil
                }
            )
        }
    }

    @ViewBuilder
    private var selectedSystemView: some View {
        switch selectedSection {
        case .equipment:
            equipmentSection
        case .profile:
            profileSection
        case .gacha:
            gachaSection
        case .fishing:
            fishingSection
        case .achievements:
            achievementSection
        case .backpack:
            backpackSection
        case .leaderboard:
            leaderboardSection
        case .store:
            storeSection
        default:
            EmptyView()
        }
    }

    private var homeStage: some View {
        GeometryReader { proxy in
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.characterName)
                            .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                        Label("Lv.\(store.playerLevel) · Power \(store.combatPower.formatted())", systemImage: "bolt.shield.fill")
                            .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Spacer()

                    Menu {
                        Button("Combat Power Rankings", systemImage: "chart.bar.fill") { selectedSection = .leaderboard }
                        Button("Account Settings", systemImage: "person.crop.circle.badge.gearshape") { showAccountSettings = true }
                        Button("Background Music", systemImage: "music.note.list") { showMusicList = true }
                        Button(audioManager.isMuted ? "Enable Sound & Music" : "Mute", systemImage: audioManager.isMuted ? "speaker.wave.2.fill" : "speaker.slash.fill") {
                            audioManager.toggleMute()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.circle.fill")
                            .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(.black.opacity(0.32), in: Circle())
                    }
                }
                .padding(14)
                .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 18))

                KenneyCharacterView(isWalking: foxIsWalking)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(1.35)
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 7)

                Button {
                    audioManager.playEffect(.battleStart)
                    registerHomeTap()
                    showBattle = true
                } label: {
                    Label("Start Level \(battleLevel)", systemImage: "play.fill")
                        .font(.custom("BoldPixels", size: 18, relativeTo: .headline))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(color: .cyan))
                .accessibilityHint("Enter battle")
                .padding(.bottom, 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 68)
            .padding(.bottom, 116)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(alignment: .bottom) {
                SnowBlockPlatform()
                    .frame(width: proxy.size.width + 80, height: 58)
                    .padding(.bottom, 96)
                    .allowsHitTesting(false)
            }

        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var bottomNavigation: some View {
        HStack(spacing: 4) {
            BottomNavButton(title: "Backpack", icon: "backpack.fill", isSelected: selectedSection == .backpack) {
                selectSection(.backpack)
            }
            BottomNavButton(title: "Summon", icon: "sparkles", isSelected: selectedSection == .gacha) {
                selectSection(.gacha)
            }
            BottomNavButton(title: "Fishing", icon: "fish.fill", isSelected: selectedSection == .fishing) {
                selectSection(.fishing)
            }
            BottomNavButton(title: "Home", icon: "house.fill", isSelected: selectedSection == .overview) {
                selectSection(.overview)
            }
            BottomNavButton(title: "Profile", icon: "person.crop.circle.fill", isSelected: selectedSection == .profile) {
                selectSection(.profile)
            }
            BottomNavButton(title: "Store", icon: "bag.fill", isSelected: selectedSection == .store) {
                selectSection(.store)
            }
            BottomNavButton(title: "Achievements", icon: "trophy.fill", isSelected: selectedSection == .achievements) {
                selectSection(.achievements)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)
        }
    }

    private func selectSection(_ section: GameSection) {
        audioManager.playEffect(.tap)
        withAnimation(.easeOut(duration: 0.2)) {
            selectedSection = section
        }
    }

    private var resourceStrip: some View {
        HStack(spacing: 10) {
            ResourcePill(title: "Gold", value: store.gold.formatted(), icon: "circle.fill", color: .yellow)
            ResourcePill(title: "Gems", value: store.gems.formatted(), icon: "diamond.fill", color: .cyan)
            ResourcePill(title: "Fish", value: store.fish.formatted(), icon: "fish.fill", color: .mint)
            ResourcePill(title: "Skill Pts.", value: store.skillPoints.formatted(), icon: "bolt.fill", color: .orange)
        }
    }

    private var sectionPicker: some View {
        Picker("Game Systems", selection: $selectedSection) {
            ForEach(sections, id: \.self) { section in
                Text(section.title).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .tint(.cyan)
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Expedition Console")
                .font(.custom("BoldPixels", size: 24, relativeTo: .title2))

            Text(store.message)
                .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                .foregroundStyle(.white.opacity(0.68))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 12) {
                ActionCard(title: "Enter Battle", subtitle: "Mac Boomerang Throw", icon: "bolt.fill", color: .pink) {
                    showBattle = true
                }
                ActionCard(title: "Ice Lake Fishing", subtitle: "QTE Mini-Game", icon: "fish.fill", color: .mint) {
                    store.fishAtLake()
                }
            }

            Text("Equipment Setup")
                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))

            ForEach(store.gear) { item in
                GearRow(item: item) {
                    store.upgrade(item)
                }
            }

            Text("System Status")
                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))

            HStack(spacing: 12) {
                ProgressCard(title: "7-Star Pity", value: "\(store.pity) / 80", progress: Double(store.pity) / 80, color: .purple)
                ProgressCard(title: "Defeat Goal", value: "\(store.defeatedEnemies) / 100", progress: Double(store.defeatedEnemies) / 100, color: .orange)
            }
        }
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Equipment Vault", subtitle: "Review your collected gear and switch each equipped slot.")

            Button {
                selectedSection = .gacha
            } label: {
                Label("Go to Aurora Summon: draw gear of different rarities", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(color: .purple))

            ForEach(store.gear) { item in
                GearDetailCard(item: item) {
                    store.upgrade(item)
                }
            }
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Character Profile", subtitle: "Choose a slot, then change \(store.characterName)'s equipment style.")

            HStack(spacing: 14) {
                KenneyCharacterView(isWalking: false)
                    .frame(width: 118, height: 150)
                    .scaleEffect(0.58)
                    .frame(width: 118, height: 150)
                    .clipped()

                VStack(alignment: .leading, spacing: 6) {
                    Text(store.characterName)
                        .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                    Text("Lv.\(store.playerLevel)")
                        .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()
            }
            .padding(16)
            .background(
                LinearGradient(colors: [.cyan.opacity(0.18), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 20)
            )

            CombatPowerCard(value: store.combatPower)

            HStack(spacing: 10) {
                ProfileStatCard(title: "Attack", value: "\(store.finalAttack)", bonus: "+\(store.equipmentBonus(for: .attack).formatted(.number.precision(.fractionLength(1))))%", color: .pink)
                ProfileStatCard(title: "Health", value: "\(store.finalHealth)", bonus: "+\(store.equipmentBonus(for: .health).formatted(.number.precision(.fractionLength(1))))%", color: .green)
            }

            HStack(spacing: 10) {
                ProfileStatCard(title: "Crit Rate", value: "\(store.finalCritRate.formatted(.number.precision(.fractionLength(1))))%", bonus: "Gear +\(store.equipmentBonus(for: .critRate).formatted(.number.precision(.fractionLength(1))))%", color: .orange)
                ProfileStatCard(title: "Crit Damage", value: "\(store.finalCritDamage.formatted(.number.precision(.fractionLength(1))))%", bonus: "Gear +\(store.equipmentBonus(for: .critDamage).formatted(.number.precision(.fractionLength(1))))%", color: .purple)
            }

            ContinuousUpgradeButton(action: {
                store.upgradeCharacter()
            }) {
                HStack {
                    Label("Upgrade to Lv.\(store.playerLevel + 1)", systemImage: "arrow.up.circle.fill")
                    Spacer()
                    Text("\(store.characterUpgradeCost.formatted()) Fish")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(color: .cyan))

            Text("Currently Equipped")
                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))

            HStack(spacing: 8) {
                ForEach(GearSlot.allCases) { slot in
                    let equippedColor = store.equippedItem(for: slot)?.rarityColor ?? slot.accent

                    Button {
                        selectedGearSlot = slot
                        selectedProfileGearID = nil
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: slot.symbol)
                            Text(slot.rawValue)
                                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                        }
                        .foregroundStyle(selectedGearSlot == slot ? equippedColor : equippedColor.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedGearSlot == slot ? equippedColor.opacity(0.16) : .white.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            ProfileSlotRow(
                slot: selectedGearSlot,
                item: store.equippedItem(for: selectedGearSlot)
            )

            Text("\(selectedGearSlot.rawValue) Styles")
                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))

            ForEach(store.gear.filter { $0.slot == selectedGearSlot }) { item in
                ProfileGearRow(
                    item: item,
                    isEquipped: store.equippedGearIDs[item.slot] == item.id,
                    onSelect: {
                        selectedProfileGearID = item.id
                    },
                    onEquip: {
                        store.equip(item)
                    },
                    onUpgrade: {
                        store.upgrade(item)
                    }
                )

                if selectedProfileGearID == item.id {
                    ProfileGearDetailCard(item: item) {
                        pendingDestroy = item
                    }
                }
            }

            SkillLoadoutSection(store: store)
        }
    }

    private var gachaSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Aurora Summon", subtitle: "Each summon grants 1-, 3-, 5-, or 7-star gear. Soft pity starts at 70 pulls; hard pity is 80.")

            VStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.custom("BoldPixels", size: 46, relativeTo: .largeTitle))
                    .foregroundStyle(.cyan, .purple)

                Text("North Star Equipment Pool")
                    .font(.custom("BoldPixels", size: 24, relativeTo: .title2))

                Text("Pull \(store.pity) · \(max(0, 80 - store.pity)) to Hard Pity")
                    .foregroundStyle(.white.opacity(0.65))

                ProgressView(value: Double(store.pity), total: 80)
                    .tint(.purple)

                HStack(spacing: 10) {
                    Button {
                        store.pullCard()
                        if store.lastPulledGear != nil {
                            audioManager.playGachaSuperEffect()
                            showGachaReveal = true
                        }
                    } label: {
                        Label("Single · 160", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .purple))

                    Button {
                        store.pullTenCards()
                        if store.lastPulledGear != nil {
                            audioManager.playGachaSuperEffect()
                            showGachaReveal = true
                        }
                    } label: {
                        Label("10 Pulls · 1,600", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .orange))
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [.purple.opacity(0.32), .cyan.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 24)
            )

            SkillPoolCard(store: store, showReveal: $showSkillReveal)

            Text(store.message)
                .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var storeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Store", subtitle: "Stock up for your next ice-lake expedition.")

            if store.skillSlotCount < 2 {
                StoreProductCard(
                    title: "Second Skill Slot",
                    detail: "Equip two skills at the same time",
                    price: "NT$66",
                    icon: "rectangle.stack.badge.plus",
                    color: .orange,
                    isFeatured: false
                ) {
                    store.purchaseSkillSlot()
                }
            }

            StoreProductCard(
                title: "Starter Bundle",
                detail: "1,000,000 Gold · 88,888 Gems · 1,000 Fish",
                price: "NT$888",
                icon: "gift.fill",
                color: .yellow,
                isFeatured: true
            ) {
                store.purchaseStarterPack()
            }

            Text("Standard Bundles")
                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))

            StoreProductCard(
                title: "Gold Bundle",
                detail: "100,000 Gold",
                price: "NT$33",
                icon: "circle.fill",
                color: .orange,
                isFeatured: false
            ) {
                store.purchaseGoldPack()
            }

            StoreProductCard(
                title: "Gem Bundle",
                detail: "1,600 Gems",
                price: "NT$33",
                icon: "diamond.fill",
                color: .cyan,
                isFeatured: false
            ) {
                store.purchaseGemPack()
            }

            StoreProductCard(
                title: "Fish Bundle",
                detail: "100 Fish",
                price: "NT$33",
                icon: "fish.fill",
                color: .mint,
                isFeatured: false
            ) {
                store.purchaseFishPack()
            }

            StoreProductCard(
                title: "Skill Point Bundle",
                detail: "10 Skill Points",
                price: "NT$33",
                icon: "bolt.fill",
                color: .yellow,
                isFeatured: false
            ) {
                store.purchaseSkillPointPack()
            }

            Text("Test purchases only. App Store payments can be added for release.")
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var fishingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Ice Lake Mines", subtitle: "Break ice to uncover water, clues, and mines. Fish in water grant bonus rewards.")

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Fish")
                        .foregroundStyle(.white.opacity(0.6))
                    Text("\(store.fish) Fish")
                        .font(.custom("BoldPixels", size: 32, relativeTo: .largeTitle))
                }
                Spacer()
                Image(systemName: "fish.fill")
                    .font(.custom("BoldPixels", size: 48, relativeTo: .largeTitle))
                    .foregroundStyle(.mint)
            }
            .padding(20)
            .background(.mint.opacity(0.14), in: RoundedRectangle(cornerRadius: 20))

            HStack(spacing: 8) {
                ForEach([1, 2, 3], id: \.self) { difficulty in
                    MinefieldDifficultyButton(
                        title: "Difficulty \(difficulty)",
                        isSelected: minefieldDifficulty == difficulty
                    ) {
                        startMinefield(difficulty: difficulty)
                    }
                }
            }

            Text(minefieldStatus)
                .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                .foregroundStyle(minefieldFinished ? .mint : .white.opacity(0.68))

            HStack(spacing: 8) {
                MinefieldModeButton(title: "Dig Ice", icon: "hammer.fill", isSelected: minefieldMode == .dig) {
                    minefieldMode = .dig
                }
                MinefieldModeButton(title: "Place Flag", icon: "flag.fill", isSelected: minefieldMode == .flag) {
                    minefieldMode = .flag
                }
            }

            HStack {
                Text("Tap a number to clear nearby ice")
                Spacer()
                Text("Flags: \(flaggedMinefieldCells.count)")
            }
            .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
            .foregroundStyle(.white.opacity(0.56))

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: minefieldSize),
                spacing: 5
            ) {
                ForEach(minefieldCells.indices, id: \.self) { index in
                    Button {
                        if revealedMinefieldCells[index] {
                            chordMinefieldCell(at: index)
                        } else if minefieldMode == .flag {
                            toggleMinefieldFlag(at: index)
                        } else {
                            revealMinefieldCell(at: index)
                        }
                    } label: {
                        MinefieldCellView(
                            value: minefieldCells[index],
                            isRevealed: revealedMinefieldCells[index],
                            isMine: minefieldMines.contains(index),
                            hasFish: minefieldFish.contains(index),
                            isFlagged: flaggedMinefieldCells.contains(index),
                            gridSize: minefieldSize
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(minefieldFinished)
                }
            }
            .padding(10)
            .background(.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

            if let reward = minefieldReward {
                let didSucceed = reward > 0

                VStack(spacing: 6) {
                    Text(didSucceed ? "Challenge Complete" : "Challenge Failed")
                        .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
                        .foregroundStyle(didSucceed ? .mint : .red)
                    Text(didSucceed ? "Earned \(reward) Fish" : "No rewards this time")
                        .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                }
                .frame(maxWidth: .infinity)
                .padding(14)
                .background((didSucceed ? Color.mint : Color.red).opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            }

            Text("Win reward: \(minefieldSize)×\(minefieldSize) base Fish + found Fish × \(minefieldSize)")
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .foregroundStyle(.white.opacity(0.58))

        }
        .onAppear {
            startMinefield(difficulty: minefieldDifficulty)
        }
    }

    private var leaderboardTitle: String {
        switch leaderboardCategory {
        case "Character Level":
            return "Character Level Rankings"
        case "Defeats":
            return "Defeat Rankings"
        case "Fish Caught":
            return "Fish Caught Rankings"
        default:
            return "Combat Power Rankings"
        }
    }

    private var leaderboardIcon: String {
        switch leaderboardCategory {
        case "Character Level":
            return "arrow.up.circle.fill"
        case "Defeats":
            return "shield.fill"
        case "Fish Caught":
            return "fish.fill"
        default:
            return "trophy.fill"
        }
    }

    private var leaderboardValue: Int {
        switch leaderboardCategory {
        case "Character Level":
            return store.playerLevel
        case "Defeats":
            return store.defeatedEnemies
        case "Fish Caught":
            return store.fishCaught
        default:
            return store.combatPower
        }
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                sectionTitle("Rankings", subtitle: "Choose a category to view your current ranking.")

                Spacer()

                Button {
                    selectedSection = .overview
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .accessibilityLabel("Return Home")
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(["Combat Power", "Character Level", "Defeats", "Fish Caught"], id: \.self) { category in
                    Button {
                        leaderboardCategory = category
                    } label: {
                        Text(category)
                            .font(.custom("BoldPixels", size: 16, relativeTo: .subheadline))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(leaderboardCategory == category ? .black : .yellow)
                            .background(
                                leaderboardCategory == category ? Color.yellow : Color.white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Image(systemName: leaderboardIcon)
                    .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 4) {
                    Text(leaderboardTitle)
                        .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                    Text("Current Player")
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("#1")
                        .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
                        .foregroundStyle(.yellow)
                    Text(leaderboardValue.formatted())
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(18)
            .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var backpackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Backpack", subtitle: "Manage expedition resources and achievement rewards.")

            Text("Equipment Slots")
                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))

            HStack(spacing: 8) {
                ForEach(GearSlot.allCases) { slot in
                    Button {
                        selectedBackpackSlot = slot
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: slot.symbol)
                            Text(slot.rawValue)
                                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                        }
                        .foregroundStyle(selectedBackpackSlot == slot ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedBackpackSlot == slot ? Color.gray.opacity(0.42) : Color.gray.opacity(0.18),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(selectedBackpackSlot == slot ? 0.8 : 0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                selectedSection = .gacha
            } label: {
                Label("Go to Aurora Summon", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(color: .purple))

            if let selectedBackpackSlot {
                let filteredGear = store.gear
                    .filter { $0.slot == selectedBackpackSlot }
                    .sorted {
                        if $0.stars != $1.stars {

                            return $0.stars > $1.stars
                        }

                        return $0.level > $1.level
                    }

                if filteredGear.isEmpty {
                    Text("No equipment in this category.")
                        .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 28)
                } else {
                    ForEach(filteredGear) { item in
                        GearDetailCard(
                            item: item,
                            onDestroy: {
                                pendingDestroy = item
                            }
                        ) {
                            store.upgrade(item)
                        }
                    }
                }
            } else {
                Text("Choose an equipment category first.")
                    .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 28)
            }
        }
    }

    private var skillSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Skill Card Pool", subtitle: "Draw, equip, and upgrade battle skills. Skill Points improve duration and power.")

            HStack(spacing: 10) {
                Text("Skill Points: \(store.skillPoints)")
                    .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                    .foregroundStyle(.yellow)
                Spacer()
                Text("Skill Slots \(store.equippedSkillIDs.count)/\(store.skillSlotCount)")
                    .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                    .foregroundStyle(.cyan)
            }

            Button {
                store.drawSkillCard()
            } label: {
                Label("Draw Skill Card · 200 Gems", systemImage: "square.stack.3d.up.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(color: .purple))

            if store.skillSlotCount < 2 {
                Button {
                    store.purchaseSkillSlot()
                } label: {
                    Label("Purchase: Unlock Second Skill Slot", systemImage: "lock.open.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(color: .orange))
            }

            ForEach(store.skills, id: \.id) { skill in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: skill.kind.icon)
                            .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                            .foregroundStyle(.cyan)
                            .frame(width: 42, height: 42)
                            .background(.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(skill.kind.rawValue) · Lv.\(skill.level)")
                                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                            Text(skill.kind.detail)
                                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                                .foregroundStyle(.white.opacity(0.68))
                            Text("Duration \(skill.duration)s · Power ×\(skill.intensity, specifier: "%.1f")")
                                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                                .foregroundStyle(.yellow)
                        }

                        Spacer()

                        Button(store.equippedSkillIDs.contains(skill.id) ? "Unequip" : "Equip") {
                            store.equipSkill(skill)
                        }
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .foregroundStyle(.cyan)
                    }

                    HStack {
                        ContinuousUpgradeButton(action: {
                            store.upgradeSkill(skill)
                        }) {
                            Text("Upgrade with Skill Points (\(skill.upgradeCost))")
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .yellow))
                        Spacer()
                    }
                }
                .padding(14)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Achievements", subtitle: "Battle, summoning, and fishing progress are tracked independently.")

            Button {
                store.claimAllAchievements()
            } label: {
                Label("Claim All", systemImage: "gift.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(color: .yellow))

            AchievementRow(id: "musicRomanzaAndaluza", title: "Voice of Andalusia", detail: "Finish Romanza Andaluza without muting", progress: store.completedMusicTracks.contains(SarasateTrack.romanzaAndaluza.id) ? 1 : 0, total: 1, reward: 16_000, icon: "music.note", isClaimed: store.claimedAchievements.contains("musicRomanzaAndaluza")) {
                store.claimAchievement(id: "musicRomanzaAndaluza", progress: store.completedMusicTracks.contains(SarasateTrack.romanzaAndaluza.id) ? 1 : 0, total: 1, reward: 16_000)
            }
            AchievementRow(id: "musicCapriceBasque", title: "Basque String Connoisseur", detail: "Finish Caprice Basque without muting", progress: store.completedMusicTracks.contains(SarasateTrack.capriceBasque.id) ? 1 : 0, total: 1, reward: 16_000, icon: "music.note", isClaimed: store.claimedAchievements.contains("musicCapriceBasque")) {
                store.claimAchievement(id: "musicCapriceBasque", progress: store.completedMusicTracks.contains(SarasateTrack.capriceBasque.id) ? 1 : 0, total: 1, reward: 16_000)
            }
            AchievementRow(id: "musicIntroductionTarantella", title: "Tarantella Fire Listener", detail: "Finish Introduction and Tarantella without muting", progress: store.completedMusicTracks.contains(SarasateTrack.introductionTarantella.id) ? 1 : 0, total: 1, reward: 16_000, icon: "music.note", isClaimed: store.claimedAchievements.contains("musicIntroductionTarantella")) {
                store.claimAchievement(id: "musicIntroductionTarantella", progress: store.completedMusicTracks.contains(SarasateTrack.introductionTarantella.id) ? 1 : 0, total: 1, reward: 16_000)
            }
            AchievementRow(id: "musicZapateado", title: "Zapateado Dance King", detail: "Finish Zapateado without muting", progress: store.completedMusicTracks.contains(SarasateTrack.zapateado.id) ? 1 : 0, total: 1, reward: 16_000, icon: "music.note", isClaimed: store.claimedAchievements.contains("musicZapateado")) {
                store.claimAchievement(id: "musicZapateado", progress: store.completedMusicTracks.contains(SarasateTrack.zapateado.id) ? 1 : 0, total: 1, reward: 16_000)
            }
            AchievementRow(id: "musicAirsEspagnols", title: "Spanish Tunes Listener", detail: "Finish Airs Espagnols without muting", progress: store.completedMusicTracks.contains(SarasateTrack.airsEspagnols.id) ? 1 : 0, total: 1, reward: 16_000, icon: "music.note", isClaimed: store.claimedAchievements.contains("musicAirsEspagnols")) {
                store.claimAchievement(id: "musicAirsEspagnols", progress: store.completedMusicTracks.contains(SarasateTrack.airsEspagnols.id) ? 1 : 0, total: 1, reward: 16_000)
            }
            AchievementRow(id: "musicLaChasse", title: "La chasse Listener", detail: "Finish La chasse without muting", progress: store.completedMusicTracks.contains(SarasateTrack.laChasse.id) ? 1 : 0, total: 1, reward: 16_000, icon: "music.note", isClaimed: store.claimedAchievements.contains("musicLaChasse")) {
                store.claimAchievement(id: "musicLaChasse", progress: store.completedMusicTracks.contains(SarasateTrack.laChasse.id) ? 1 : 0, total: 1, reward: 16_000)
            }
            AchievementRow(id: "musicRomanceSansParoles", title: "Romance Listener", detail: "Finish Romance sans Paroles and Rondo élégant without muting", progress: store.completedMusicTracks.contains(SarasateTrack.romanceSansParoles.id) ? 1 : 0, total: 1, reward: 16_000, icon: "music.note", isClaimed: store.claimedAchievements.contains("musicRomanceSansParoles")) {
                store.claimAchievement(id: "musicRomanceSansParoles", progress: store.completedMusicTracks.contains(SarasateTrack.romanceSansParoles.id) ? 1 : 0, total: 1, reward: 16_000)
            }
            AchievementRow(id: "firstBattle", title: "First Frost Battle", detail: "Complete your first battle", progress: min(store.defeatedEnemies, 1), total: 1, reward: 50, icon: "flag.fill", isClaimed: store.claimedAchievements.contains("firstBattle")) {
                store.claimAchievement(id: "firstBattle", progress: min(store.defeatedEnemies, 1), total: 1, reward: 50)
            }
            AchievementRow(id: "iceHunter", title: "Ice Lake Hunter", detail: "Catch 100 Fish", progress: store.fishCaught, total: 100, reward: 100, icon: "fish.fill", isClaimed: store.claimedAchievements.contains("iceHunter")) {
                store.claimAchievement(id: "iceHunter", progress: store.fishCaught, total: 100, reward: 100)
            }
            AchievementRow(id: "auroraSummoner", title: "Aurora Summon Master", detail: "Complete 200 summons", progress: store.totalPulls, total: 200, reward: 200, icon: "sparkles", isClaimed: store.claimedAchievements.contains("auroraSummoner")) {
                store.claimAchievement(id: "auroraSummoner", progress: store.totalPulls, total: 200, reward: 200)
            }
            AchievementRow(id: "snowCleaner", title: "Snowfield Finisher", detail: "Defeat 100 enemies", progress: store.defeatedEnemies, total: 100, reward: 150, icon: "shield.fill", isClaimed: store.claimedAchievements.contains("snowCleaner")) {
                store.claimAchievement(id: "snowCleaner", progress: store.defeatedEnemies, total: 100, reward: 150)
            }
            AchievementRow(id: "levelFive", title: "Frostland Awakened", detail: "Reach character level 5", progress: store.playerLevel, total: 5, reward: 100, icon: "arrow.up.circle.fill", isClaimed: store.claimedAchievements.contains("levelFive")) {
                store.claimAchievement(id: "levelFive", progress: store.playerLevel, total: 5, reward: 100)
            }
            AchievementRow(id: "levelTen", title: "Polar Overlord", detail: "Reach character level 10", progress: store.playerLevel, total: 10, reward: 250, icon: "star.fill", isClaimed: store.claimedAchievements.contains("levelTen")) {
                store.claimAchievement(id: "levelTen", progress: store.playerLevel, total: 10, reward: 250)
            }
            AchievementRow(id: "seasonedAngler", title: "Abyss Angler", detail: "Catch 500 Fish", progress: store.fishCaught, total: 500, reward: 300, icon: "fish.fill", isClaimed: store.claimedAchievements.contains("seasonedAngler")) {
                store.claimAchievement(id: "seasonedAngler", progress: store.fishCaught, total: 500, reward: 300)
            }
            AchievementRow(id: "masterAngler", title: "Ice Lake Dragon", detail: "Catch 1,000 Fish", progress: store.fishCaught, total: 1_000, reward: 600, icon: "water.waves", isClaimed: store.claimedAchievements.contains("masterAngler")) {
                store.claimAchievement(id: "masterAngler", progress: store.fishCaught, total: 1_000, reward: 600)
            }
            AchievementRow(id: "firstTenPulls", title: "First Aurora Summon", detail: "Complete 10 summons", progress: store.totalPulls, total: 10, reward: 100, icon: "wand.and.stars", isClaimed: store.claimedAchievements.contains("firstTenPulls")) {
                store.claimAchievement(id: "firstTenPulls", progress: store.totalPulls, total: 10, reward: 100)
            }
            AchievementRow(id: "summonCollector", title: "Universal Collector", detail: "Complete 50 summons", progress: store.totalPulls, total: 50, reward: 300, icon: "sparkles", isClaimed: store.claimedAchievements.contains("summonCollector")) {
                store.claimAchievement(id: "summonCollector", progress: store.totalPulls, total: 50, reward: 300)
            }
            AchievementRow(id: "battleVeteran", title: "Frostfang Veteran", detail: "Defeat 10 enemies", progress: store.defeatedEnemies, total: 10, reward: 120, icon: "bolt.fill", isClaimed: store.claimedAchievements.contains("battleVeteran")) {
                store.claimAchievement(id: "battleVeteran", progress: store.defeatedEnemies, total: 10, reward: 120)
            }
            AchievementRow(id: "battleMaster", title: "Battlefield Tyrant", detail: "Defeat 500 enemies", progress: store.defeatedEnemies, total: 500, reward: 500, icon: "flame.fill", isClaimed: store.claimedAchievements.contains("battleMaster")) {
                store.claimAchievement(id: "battleMaster", progress: store.defeatedEnemies, total: 500, reward: 500)
            }
            AchievementRow(id: "gearCollector", title: "Gear Collector", detail: "Own 10 equipment pieces", progress: store.gear.count, total: 10, reward: 150, icon: "shippingbox.fill", isClaimed: store.claimedAchievements.contains("gearCollector")) {
                store.claimAchievement(id: "gearCollector", progress: store.gear.count, total: 10, reward: 150)
            }
            AchievementRow(id: "legendaryHunter", title: "Seven-Star Chosen", detail: "Obtain 1 seven-star item", progress: store.gear.contains { $0.stars == 7 } ? 1 : 0, total: 1, reward: 400, icon: "crown.fill", isClaimed: store.claimedAchievements.contains("legendaryHunter")) {
                store.claimAchievement(id: "legendaryHunter", progress: store.gear.contains { $0.stars == 7 } ? 1 : 0, total: 1, reward: 400)
            }
            AchievementRow(id: "completeLoadout", title: "Frost Fox Loadout", detail: "Equip all three gear slots", progress: GearSlot.allCases.allSatisfy { store.equippedItem(for: $0) != nil } ? 1 : 0, total: 1, reward: 200, icon: "person.fill.checkmark", isClaimed: store.claimedAchievements.contains("completeLoadout")) {
                store.claimAchievement(id: "completeLoadout", progress: GearSlot.allCases.allSatisfy { store.equippedItem(for: $0) != nil } ? 1 : 0, total: 1, reward: 200)
            }
        }
    }

    private func registerHomeTap() {
        homeTapCount += 1

        guard homeTapCount >= 18 else { return }

        store.gems += 1_600
        store.gold += 100_000
        store.fish += 100
        store.fishCaught += 100
        homeTapCount = 0
    }

    private func startMinefield(difficulty: Int) {
        minefieldDifficulty = difficulty
        minefieldSize = difficulty == 1 ? 7 : difficulty == 2 ? 11 : 17
        minefieldFoundFish = 0
        flaggedMinefieldCells = []
        minefieldMode = .dig
        minefieldHasStarted = false
        minefieldFinished = false
        minefieldReward = nil
        minefieldStatus = "The ice has been rearranged. Find a safe path."
        configureMinefield(excluding: nil)
    }

    private func configureMinefield(excluding protectedIndices: Set<Int>?) {
        let cellCount = minefieldSize * minefieldSize
        let mineCount = max(1, Int(Double(cellCount) * 0.2))
        let protectedIndices = protectedIndices ?? []
        let availableIndices = (0..<cellCount).filter { !protectedIndices.contains($0) }

        minefieldMines = Set(availableIndices.shuffled().prefix(mineCount))
        minefieldFish = []
        minefieldCells = Array(repeating: 0, count: cellCount)
        revealedMinefieldCells = Array(repeating: false, count: cellCount)

        for index in 0..<cellCount where !minefieldMines.contains(index) {
            let row = index / minefieldSize
            let column = index % minefieldSize
            var adjacentMines = 0

            for neighborRow in max(0, row - 1)...min(minefieldSize - 1, row + 1) {
                for neighborColumn in max(0, column - 1)...min(minefieldSize - 1, column + 1) {
                    let neighbor = neighborRow * minefieldSize + neighborColumn
                    if minefieldMines.contains(neighbor) {
                        adjacentMines += 1
                    }
                }
            }

            minefieldCells[index] = adjacentMines
        }

        minefieldFish = Set((0..<cellCount)
            .filter { !minefieldMines.contains($0) && minefieldCells[$0] == 0 }
            .shuffled()
            .prefix(minefieldDifficulty + 2))
    }

    private func toggleMinefieldFlag(at index: Int) {
        guard !minefieldFinished, !revealedMinefieldCells[index] else { return }

        if flaggedMinefieldCells.contains(index) {
            flaggedMinefieldCells.remove(index)
        } else {
            flaggedMinefieldCells.insert(index)
        }
    }

    private func revealMinefieldCell(at index: Int) {
        guard !minefieldFinished else { return }

        if revealedMinefieldCells[index] {
            chordMinefieldCell(at: index)
            return
        }

        guard !flaggedMinefieldCells.contains(index) else { return }

        if !minefieldHasStarted {
            minefieldHasStarted = true
            let protectedIndices = Set([index] + minefieldNeighborIndices(of: index))
            configureMinefield(excluding: protectedIndices)
        }

        if minefieldMines.contains(index) {
            revealedMinefieldCells[index] = true
            minefieldFinished = true
            minefieldReward = 0
            audioManager.playEffect(.battleFailure)
            minefieldStatus = "Challenge failed: you hit a mine. No rewards this time."
            revealedMinefieldCells = Array(repeating: true, count: minefieldCells.count)
            return
        }

        revealSafeMinefieldCells(startingAt: index)
        completeMinefieldIfNeeded()
    }

    private func chordMinefieldCell(at index: Int) {
        guard minefieldCells[index] > 0 else { return }

        let neighbors = minefieldNeighborIndices(of: index)
        let flaggedCount = neighbors.filter { flaggedMinefieldCells.contains($0) }.count
        guard flaggedCount == minefieldCells[index] else {
            minefieldStatus = "The flag count does not match this number yet."
            return
        }

        for neighbor in neighbors where !revealedMinefieldCells[neighbor] && !flaggedMinefieldCells.contains(neighbor) {
            if minefieldMines.contains(neighbor) {
                minefieldFinished = true
                minefieldReward = 0
                audioManager.playEffect(.battleFailure)
                minefieldStatus = "Challenge failed: incorrect flags hit a mine. No rewards this time."
                minefieldFinished = true
                minefieldReward = 0
                audioManager.playEffect(.battleFailure)
                minefieldStatus = "Challenge failed: incorrect flags hit a mine. No rewards this time."
                revealedMinefieldCells = Array(repeating: true, count: minefieldCells.count)
                return
            }

            revealSafeMinefieldCells(startingAt: neighbor)
        }

        completeMinefieldIfNeeded()
    }

    private func completeMinefieldIfNeeded() {
        let safeCells = minefieldCells.indices.filter { !minefieldMines.contains($0) }
        let revealedSafeCells = safeCells.filter { revealedMinefieldCells[$0] }
        guard revealedSafeCells.count == safeCells.count else {
            minefieldStatus = "Safe! Found \(minefieldFoundFish) fish in the water."
            return
        }

        let baseReward = minefieldSize * minefieldSize
        let reward = baseReward + minefieldFoundFish * minefieldSize
        store.fish += reward
        store.fishCaught += reward
        minefieldFinished = true
        minefieldReward = reward
        audioManager.playEffect(.battleSuccess)
        minefieldStatus = "Challenge complete: \(baseReward) base + \(minefieldFoundFish * minefieldSize) bonus Fish."
    }

    private func minefieldNeighborIndices(of index: Int) -> [Int] {
        let row = index / minefieldSize
        let column = index % minefieldSize
        return (max(0, row - 1)...min(minefieldSize - 1, row + 1)).flatMap { neighborRow in
            (max(0, column - 1)...min(minefieldSize - 1, column + 1)).compactMap { neighborColumn in
                let neighbor = neighborRow * minefieldSize + neighborColumn
                return neighbor == index ? nil : neighbor
            }
        }
    }

    private func revealSafeMinefieldCells(startingAt start: Int) {
        var pending = [start]
        var visited = Set<Int>()

        while let current = pending.popLast() {
            guard visited.insert(current).inserted,
                  !revealedMinefieldCells[current],
                  !minefieldMines.contains(current),
                  !flaggedMinefieldCells.contains(current) else { continue }

            revealedMinefieldCells[current] = true
            if minefieldFish.contains(current) {
                minefieldFoundFish += 1
            }

            guard minefieldCells[current] == 0 else { continue }

            pending.append(contentsOf: minefieldNeighborIndices(of: current).filter {
                !minefieldMines.contains($0)
            })
        }
    }

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
            Text(subtitle)
                .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                .foregroundStyle(.white.opacity(0.62))
        }
    }
}

struct KenneyCharacterView: View {
    let isWalking: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(0.3))
                .frame(width: 150, height: 18)
                .offset(y: 91)
                .blur(radius: 5)

            TimelineView(.animation(minimumInterval: 0.16, paused: !isWalking)) { context in
                let frame = Int(context.date.timeIntervalSinceReferenceDate / 0.16)
                let imageName = frame.isMultiple(of: 2) ? "KenneyBeigeWalkA" : "KenneyBeigeWalkB"

                Image(isWalking ? imageName : "KenneyBeigeIdle")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 144, height: 144)
            }
            .offset(y: 2)
            .shadow(color: .black.opacity(0.22), radius: 3, y: 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Polar explorer wearing a helmet and sunglasses, holding a Mac")
    }
}

struct PolarFoxView: View {
    let isWalking: Bool

    private let navy = Color(red: 0.04, green: 0.10, blue: 0.20)
    private let backpackGreen = Color(red: 0.18, green: 0.25, blue: 0.24)
    private let eyeBlue = Color(red: 0.12, green: 0.45, blue: 0.72)

    var body: some View {
        ZStack {
            Ellipse()
                .fill(.black.opacity(0.25))
                .frame(width: 190, height: 26)
                .offset(y: 116)
                .blur(radius: 8)

            // 大蓬尾巴與背包。
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 0.82, green: 0.87, blue: 0.92)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 96, height: 48)
                .rotationEffect(.degrees(-30))
                .offset(x: 80, y: 30)

            RoundedRectangle(cornerRadius: 20)
                .fill(backpackGreen)
                .frame(width: 64, height: 88)
                .overlay {
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.white.opacity(0.18))
                            .frame(width: 34, height: 5)
                        Text("FOX")
                            .font(.custom("BoldPixels", size: 8, relativeTo: .caption2))
                            .foregroundStyle(.white.opacity(0.78))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.5), lineWidth: 2)
                )
                .offset(x: -59, y: 33)

            // 身體、腳與衣服。
            Capsule()
                .fill(.white)
                .frame(width: 146, height: 120)
                .offset(y: 37)

            RoundedRectangle(cornerRadius: 11)
                .fill(Color(red: 0.88, green: 0.91, blue: 0.94))
                .frame(width: 29, height: 68)
                .rotationEffect(.degrees(isWalking ? 8 : -8))
                .offset(x: -37, y: 96)

            RoundedRectangle(cornerRadius: 11)
                .fill(Color(red: 0.78, green: 0.84, blue: 0.89))
                .frame(width: 29, height: 68)
                .rotationEffect(.degrees(isWalking ? -8 : 8))
                .offset(x: 37, y: 96)

            // 背包肩帶。
            Capsule()
                .stroke(backpackGreen.opacity(0.9), lineWidth: 7)
                .frame(width: 110, height: 105)
                .offset(x: -27, y: 34)

            // 頭與尖耳朵。
            Triangle()
                .fill(.white)
                .frame(width: 66, height: 78)
                .rotationEffect(.degrees(-12))
                .offset(x: -43, y: -125)

            Triangle()
                .fill(.white)
                .frame(width: 66, height: 78)
                .rotationEffect(.degrees(12))
                .offset(x: 43, y: -125)

            Triangle()
                .fill(Color(red: 0.97, green: 0.72, blue: 0.75))
                .frame(width: 31, height: 46)
                .rotationEffect(.degrees(-12))
                .offset(x: -43, y: -119)

            Triangle()
                .fill(Color(red: 0.97, green: 0.72, blue: 0.75))
                .frame(width: 31, height: 46)
                .rotationEffect(.degrees(12))
                .offset(x: 43, y: -119)

            Circle()
                .fill(.white)
                .frame(width: 148, height: 148)
                .offset(y: -55)

            // 大藍眼睛與高光。
            HStack(spacing: 31) {
                FoxEye(color: eyeBlue)
                FoxEye(color: eyeBlue)
            }
            .offset(y: -62)

            Capsule()
                .fill(navy)
                .frame(width: 19, height: 13)
                .offset(y: -35)

            Circle()
                .fill(.white.opacity(0.92))
                .frame(width: 48, height: 34)
                .offset(y: -21)

            Capsule()
                .fill(.black.opacity(0.75))
                .frame(width: 16, height: 7)
                .offset(y: -21)

            // 紅色衣服識別條。
            Capsule()
                .fill(Color(red: 0.9, green: 0.25, blue: 0.18))
                .frame(width: 112, height: 20)
                .rotationEffect(.degrees(-5))
                .offset(y: 15)
                .overlay {
                    Text("MACFOX")
                        .font(.custom("BoldPixels", size: 8, relativeTo: .caption2))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .offset(y: 15)
                }

            // 手臂與手。
            Capsule()
                .fill(.white)
                .frame(width: 25, height: 74)
                .rotationEffect(.degrees(38))
                .offset(x: -66, y: 28)

            Capsule()
                .fill(.white)
                .frame(width: 25, height: 74)
                .rotationEffect(.degrees(-38))
                .offset(x: 65, y: 28)

            Circle()
                .fill(Color(red: 0.96, green: 0.91, blue: 0.86))
                .frame(width: 23, height: 23)
                .offset(x: -87, y: 48)

            Circle()
                .fill(Color(red: 0.96, green: 0.91, blue: 0.86))
                .frame(width: 23, height: 23)
                .offset(x: 87, y: 48)

            // 左手拿 Mac。
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.66, green: 0.72, blue: 0.77))
                .frame(width: 58, height: 42)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.white.opacity(0.85), lineWidth: 1.5)
                    Image(systemName: "applelogo")
                        .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                        .foregroundStyle(navy.opacity(0.75))
                }
                .rotationEffect(.degrees(-16))
                .offset(x: -98, y: 35)

            // 戴著資源包頭盔。
            Capsule()
                .fill(Color(red: 0.52, green: 0.27, blue: 0.15))
                .frame(width: 13, height: 52)
                .rotationEffect(.degrees(-25))
                .offset(x: 92, y: 66)

            Circle()
                .fill(Color(red: 0.88, green: 0.16, blue: 0.12))
                .frame(width: 59, height: 59)
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.7), lineWidth: 2)
                }
                .offset(x: 89, y: 26)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("White polar explorer wearing sunglasses and a helmet, holding a Mac")
    }
}

struct SnowBlockPlatform: View {
    var body: some View {
        Image("HomeSnowMiddle")
            .resizable()
            .interpolation(.none)
            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
            .background(Color(red: 0.58, green: 0.78, blue: 0.92))
            .shadow(color: .black.opacity(0.48), radius: 8, y: 5)
            .zIndex(20)
            .accessibilityHidden(true)
    }
}

struct AccountSettingsView: View {
    @Bindable var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var transferCode = ""
    @State private var inheritCode = ""
    @State private var notice: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Character") {
                    TextField("Character Name", text: $store.characterName)
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            store.characterName = String(store.characterName.prefix(20))
                        }

                    Text("Up to 20 characters. Saved automatically.")
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .foregroundStyle(.secondary)
                }

                Section("Current Account") {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                            .foregroundStyle(.cyan)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.characterName)
                                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                            Text("Roald Amundsen · Lv.\(store.playerLevel)")
                                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section("Transfer Account") {
                    Button {
                        transferCode = store.makeTransferCode()
                        notice = "Transfer code created. Copy and save it; it contains your character and resources."
                    } label: {
                        Label("Create Transfer Code", systemImage: "arrow.up.right.circle")
                    }

                    if !transferCode.isEmpty {
                        Text(transferCode)
                            .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                            .textSelection(.enabled)
                            .lineLimit(3)

                        Button {
                            UIPasteboard.general.string = transferCode
                            notice = "Transfer code copied."
                        } label: {
                            Label("Copy Transfer Code", systemImage: "doc.on.doc")
                        }
                    }
                }

                Section("Restore Account") {
                    TextField("Paste Transfer Code", text: $inheritCode, axis: .vertical)
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .lineLimit(3...5)

                    Button {
                        let code = inheritCode.trimmingCharacters(in: .whitespacesAndNewlines)
                        if code.isEmpty {
                            notice = "Enter a transfer code first."
                        } else if store.inheritAccount(from: code) {
                            inheritCode = ""
                            transferCode = ""
                            notice = "Account restored. Character data updated."
                        } else {
                            notice = "Invalid or damaged transfer code. Please try again."
                        }
                    } label: {
                        Label("Restore Account", systemImage: "arrow.down.left.circle")
                    }
                }
            }
            .navigationTitle("Account Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Account Management", isPresented: Binding(
                get: { notice != nil },
                set: { if !$0 { notice = nil } }
            )) {
                Button("OK", role: .cancel) {
                    notice = nil
                }
            } message: {
                Text(notice ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SkillLoadoutSection: View {
    @Bindable var store: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Skill Loadout")
                    .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
                Spacer()
                Text("Skill Points \(store.skillPoints) · Slots \(store.equippedSkillIDs.count)/\(store.skillSlotCount)")
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.cyan)
            }

            ForEach(store.skills, id: \.id) { skill in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: skill.kind.icon)
                            .foregroundStyle(.cyan)
                            .frame(width: 34, height: 34)
                            .background(.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(skill.kind.rawValue) · Lv.\(skill.level)")
                                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                            Text(skill.kind.detail)
                                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                                .foregroundStyle(.white.opacity(0.65))
                            Text("Duration \(skill.duration)s · Power ×\(skill.intensity, specifier: "%.1f")")
                                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                                .foregroundStyle(.yellow)
                        }

                        Spacer()

                        Button(store.equippedSkillIDs.contains(skill.id) ? "Unequip" : "Equip") {
                            store.equipSkill(skill)
                        }
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .foregroundStyle(.cyan)
                    }

                    ContinuousUpgradeButton(action: {
                        store.upgradeSkill(skill)
                    }) {
                        Text("Upgrade with Skill Points (\(skill.upgradeCost))")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .yellow))
                }
                .padding(12)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

struct SkillPoolCard: View {
    @Bindable var store: GameStore
    @Binding var showReveal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Skill Pool", systemImage: "bolt.fill")
                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
                .foregroundStyle(.purple)

            Text("Summon Skill Cards, then equip them in Character Profile.")
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .foregroundStyle(.white.opacity(0.65))

            HStack(spacing: 8) {
                Button {
                    store.drawSkillCards(count: 1)
                    if !store.lastPulledSkills.isEmpty {
                        showReveal = true
                    }
                } label: {
                    Label("1 Pull · 200", systemImage: "bolt.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(color: .purple))

                Button {
                    store.drawSkillCards(count: 10)
                    if !store.lastPulledSkills.isEmpty {
                        showReveal = true
                    }
                } label: {
                    Label("10 Pulls · 2,000", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(color: .orange))
            }
        }
        .padding(16)
        .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct SkillRevealView: View {
    let items: [SkillCard]
    let onDismiss: () -> Void

    @State private var cardsVisible = false
    @State private var glow = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .purple.opacity(0.35), Color(red: 0.04, green: 0.08, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text(items.count == 10 ? "10 Skill Summons" : "Skill Summon")
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .tracking(4)
                        .foregroundStyle(.yellow)

                    ZStack {
                        Circle()
                            .fill(.purple.opacity(glow ? 0.4 : 0.12))
                            .frame(width: 220, height: 220)
                            .blur(radius: glow ? 22 : 6)

                        ForEach(0..<12, id: \.self) { index in
                            Rectangle()
                                .fill(.cyan.opacity(glow ? 0.4 : 0.08))
                                .frame(width: 2, height: 190)
                                .rotationEffect(.degrees(Double(index) * 30))
                                .scaleEffect(glow ? 1 : 0.45)
                        }

                        Image(systemName: "bolt.fill")
                            .font(.custom("BoldPixels", size: 64, relativeTo: .largeTitle))
                            .foregroundStyle(.white, .purple)
                            .shadow(color: .purple, radius: glow ? 20 : 4)
                            .rotationEffect(.degrees(cardsVisible ? 0 : -18))
                            .scaleEffect(cardsVisible ? 1 : 0.65)
                    }
                    .frame(height: 230)

                    if items.count == 10 {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 10
                        ) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, skill in
                                SkillRevealCard(skill: skill, isVisible: cardsVisible)
                                    .rotation3DEffect(
                                        .degrees(cardsVisible ? 0 : 90),
                                        axis: (x: 0, y: 1, z: 0)
                                    )
                                    .opacity(cardsVisible ? 1 : 0)
                                    .animation(
                                        .spring(response: 0.48, dampingFraction: 0.76)
                                            .delay(Double(index) * 0.08),
                                        value: cardsVisible
                                    )
                            }
                        }
                        .padding(.horizontal, 14)
                    } else if let skill = items.first {
                        SkillRevealCard(skill: skill, isVisible: cardsVisible)
                            .frame(maxWidth: 260)
                            .rotation3DEffect(
                                .degrees(cardsVisible ? 0 : 90),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .opacity(cardsVisible ? 1 : 0)
                            .animation(.spring(response: 0.65, dampingFraction: 0.72), value: cardsVisible)
                    }

                    Text(items.count == 10 ? "10 Skill Cards added to your collection" : "Skill Card added to your collection")
                        .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                        .foregroundStyle(.white.opacity(0.65))

                    Button("Go to Character Profile") {
                        onDismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .purple))
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 24)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                glow = true
            }
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.spring(response: 0.7, dampingFraction: 0.76)) {
                    cardsVisible = true
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct SkillRevealCard: View {
    let skill: SkillCard
    let isVisible: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: skill.kind.icon)
                .font(.custom("BoldPixels", size: 32, relativeTo: .largeTitle))
                .foregroundStyle(.cyan)

            Text(skill.kind.rawValue)
                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                .foregroundStyle(.white)

            Text(skill.kind.detail)
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(2)

            Text("Lv.\(skill.level) · Duration \(skill.duration)s")
                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                .foregroundStyle(.yellow)
        }
        .frame(maxWidth: .infinity, minHeight: 138)
        .padding(12)
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.8), .black.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.cyan.opacity(isVisible ? 0.9 : 0.25), lineWidth: 1.5)
        }
        .shadow(color: .purple.opacity(isVisible ? 0.65 : 0.15), radius: isVisible ? 12 : 3)
    }
}

enum BattleResult: Equatable {
    case victory
    case defeat
}

struct DamagePopup: Identifiable {
    let id = UUID()
    let amount: Int
    let isPlayer: Bool
    let isHeal: Bool
}

struct BattleView: View {
    @Bindable var store: GameStore
    @Binding var isPresented: Bool
    @Binding var level: Int

    private var enemyName: String {

        switch enemyVariant {
        case 1: return "Frost Behemoth"
        case 2: return "Storm Lord"
        case 3: return "Magma Beast"

        case 4: return "Aurora Mage"
        case 5: return "Shadow Hunter"
        case 6: return "Crystal Warden"
        case 7: return "Void Phantom"

        default: return wave >= 2 ? "Empowered Slime" : "Slime"
        }
    }

    private var enemyTint: Color {
        switch enemyVariant {
        case 1: return .cyan
        case 2: return .yellow
        case 3: return .orange
        case 4: return .purple
        case 5: return .indigo
        case 6: return .mint
        case 7: return .pink
        default: return .white
        }
    }

    private var enemyTrait: String {
        switch enemyVariant {
        case 1: return "Frost: Hits stack Freeze"
        case 2: return "Storm: Calls delayed lightning"
        case 3: return "Magma: Deals Burn damage over time"
        case 4: return "Aurora: Mixes elemental attacks"
        case 5: return "Shadow: Attacks more often"
        case 6: return "Crystal: Takes 25% less damage"
        case 7: return "Void: Higher damage and erratic paths"
        default: return "Normal: A balanced enemy"
        }
    }

    private var enemySymbol: String {
        switch enemyVariant {
        case 1: return "snowflake"
        case 2: return "bolt.fill"
        case 3: return "flame.fill"
        case 4: return "wand.and.stars"
        case 5: return "moon.stars.fill"
        case 6: return "diamond.fill"
        case 7: return "eye.fill"
        default: return "drop.fill"
        }
    }

    @State private var playerHP = 1_000
    @State private var playerMaxHP = 1_000
    @State private var enemyHP = 420
    @State private var enemyMaxHP = 420
    @State private var secondaryEnemyHP = 0
    @State private var secondaryEnemyMaxHP = 0
    @State private var enemyCount = 1
    @State private var macTargetIsSecondary = false
    @State private var distance = 0
    @State private var jumpCount = 0
    @State private var jumpMotionID = 0
    @State private var jumpHeight: CGFloat = 0
    @State private var tickCount = 0
    @State private var nextEnemyAttackTick = 0
    @State private var macFlying = false
    @State private var macFlightProgress: CGFloat = 0
    @State private var macStartX: CGFloat = 0.22
    @State private var macEndX: CGFloat = 0.78
    @State private var macStartYOffset: CGFloat = 0
    @State private var macEndYOffset: CGFloat = 0
    @State private var bombFlightProgress: CGFloat = 0
    @State private var bombStartX: CGFloat = 0.78
    @State private var bombEndX: CGFloat = 0.22
    @State private var bombStartYOffset: CGFloat = 0
    @State private var bombEndYOffset: CGFloat = 0
    @State private var enemyProjectileKind = 0
    @State private var enemyProjectileType = 0
    @State private var battleResult: BattleResult?
    @State private var damagePopups: [DamagePopup] = []
    @State private var lastDamage = 0
    @State private var worldTravel: CGFloat = 0
    @State private var enemyTravel: CGFloat = 0
    @State private var enemyJumpHeight: CGFloat = 0
    @State private var enemyDodgeMotionID = 0
    @State private var enemyDodgeOnCooldown = false
    @State private var bombFlying = false
    @State private var battleStarted = false
    @State private var burnSecondsRemaining = 0
    @State private var burnStacks = 0
    @State private var enemyBurnStacks = 0
    @State private var enemyBurnFlash = false
    @State private var freezeStacks = 0
    @State private var lightningStrikes = 0
    @State private var lightningProgress: CGFloat = 0
    @State private var isFrozen = false
    @State private var lightningWarning = false
    @State private var explosionFlash = false
    @State private var enemyVariant = 0
    @State private var wave = 1
    @State private var skillControlImmune = false
    @State private var skillNegativeAttack = false
    @State private var skillRegeneration = false
    @State private var skillRapidFire = false
    @State private var skillActiveRemaining: [UUID: Int] = [:]
    @State private var skillCooldownRemaining: [UUID: Int] = [:]
    @State private var comboCount = 0
    @State private var bestCombo = 0
    @State private var perfectDodges = 0
    @State private var combatNotice = "Combo damage increases on consecutive hits"
    @State private var enemyHitFlash = false
    @State private var playerHitFlash = false
    @State private var dodgeFlash = false
    @State private var screenShake: CGFloat = 0

    private var isEnemyEnraged: Bool {
        Double(enemyHP) / Double(max(1, enemyMaxHP)) <= 0.35
    }

    private var fishReward: Int {
        max(2, level * 2)
    }

    private var skillPointReward: Int {
        1
    }

    private var gemReward: Int {
        20 + level * 5
    }

    var body: some View {
        ZStack {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 14) {
                BattleStatusHeader(
                    level: level,
                    wave: wave,
                    totalWaves: enemyCount
                )

                BattleMomentumBar(
                    combo: comboCount,
                    perfectDodges: perfectDodges
                )
                .frame(maxWidth: .infinity, alignment: .center)

                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 330)
                    .padding(.horizontal, 14)

                Spacer(minLength: 8)
            }
            .padding(.top, 56)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()
        .clipped()
        .offset(x: screenShake)
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.height < -24 {
                        jump()
                    }
                }
        )
        .overlay {
            GeometryReader { proxy in
                ZStack {
                    VStack(spacing: 4) {
                        CompactBattleHealthBar(title: store.characterName, current: playerHP, maximum: playerMaxHP, color: .green)
                        if isFrozen {
                            Text("❄ Freeze")
                                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                                .foregroundStyle(.cyan)
                        } else if lightningWarning {
                            Text("⚡ Lightning Warning")
                                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                                .foregroundStyle(.yellow)
                        } else if explosionFlash {
                            Text("💥 Explosion")
                                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                                .foregroundStyle(.orange)
                        } else if burnStacks > 0 {
                            Text("🔥 Burn ×\(burnStacks)")
                                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                                .foregroundStyle(.orange)
                        }
                        ZStack {
                            Image("KenneyBeigeIdle")
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 74, height: 74)

                        }
                    }
                    .position(
                        x: battleStarted ? proxy.size.width * 0.22 : proxy.size.width * 0.5,
                        y: proxy.size.height - 133
                    )
                    .offset(y: -jumpHeight)
                    .animation(.easeInOut(duration: 0.65), value: battleStarted)

                    VStack(spacing: 4) {
                        CompactBattleHealthBar(title: enemyName, current: enemyHP, maximum: enemyMaxHP, color: .red)
                        if enemyBurnFlash {
                            Text("🔥 Burn Damage")
                                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                                .foregroundStyle(.orange)
                        } else if enemyBurnStacks > 0 {
                            Text("Burn ×\(enemyBurnStacks)")
                                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                                .foregroundStyle(.orange)
                        }
                        EnemyAvatar(
                            variant: enemyVariant,
                            tint: enemyTint,
                            symbol: enemySymbol,
                            isEnraged: isEnemyEnraged,
                            size: 76
                        )
                    }
                    .opacity(enemyHP > 0 ? 1 : 0)
                    .position(x: proxy.size.width * 0.78, y: proxy.size.height - 133)
                    .offset(y: -enemyJumpHeight)

                    if enemyCount > 1 && secondaryEnemyHP > 0 {
                        VStack(spacing: 4) {
                            CompactBattleHealthBar(
                                title: "\(enemyName) II",
                                current: secondaryEnemyHP,
                                maximum: secondaryEnemyMaxHP,
                                color: .orange
                            )
                            EnemyAvatar(
                                variant: enemyVariant,
                                tint: .orange,
                                symbol: enemySymbol,
                                isEnraged: isEnemyEnraged,
                                size: 64
                            )
                        }
                        .position(x: proxy.size.width * 0.62, y: proxy.size.height - 133)
                        .zIndex(8)
                    }

                    ForEach(damagePopups) { popup in
                        Text(popup.isHeal ? "+\(popup.amount)" : "-\(popup.amount)")
                            .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                            .foregroundStyle(popup.isHeal ? .green : .red)
                            .shadow(color: .black, radius: 4)
                            .position(
                                x: proxy.size.width * (popup.isPlayer ? 0.22 : 0.78),
                                y: proxy.size.height - 272 - (popup.isPlayer ? jumpHeight : enemyJumpHeight)
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(60)
                    }

                    if macFlying {
                        ZStack {
                            Circle()
                                .fill(.cyan.opacity(0.3))
                                .frame(width: 42, height: 42)
                            Image(systemName: "laptopcomputer")
                                .font(.custom("BoldPixels", size: 28, relativeTo: .title))
                                .foregroundStyle(.white)
                                .shadow(color: .cyan, radius: 12)
                            Text("Mac")
                                .font(.custom("BoldPixels", size: 9, relativeTo: .caption2))
                                .foregroundStyle(.cyan)
                                .offset(y: 20)
                        }
                        .zIndex(40)
                        .position(
                            macProjectilePoint(
                                progress: macFlightProgress,
                                canvasSize: proxy.size
                            )
                        )
                    }

                    if bombFlying {
                        Path { path in
                            let steps = 48

                            for step in 0...steps {
                                let progress = 1.42 * CGFloat(step) / CGFloat(steps)
                                let point = enemyProjectilePoint(
                                    progress: progress,
                                    canvasSize: proxy.size
                                )
                                if step == 0 {
                                    path.move(to: point)
                                } else {
                                    path.addLine(to: point)
                                }
                            }
                        }
                        .stroke(enemyProjectileColor.opacity(0.55), style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            dash: [8, 8]
                        ))
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                        .zIndex(35)

                        ZStack {
                            Circle()
                                .fill(enemyProjectileColor.opacity(0.3))
                                .frame(width: 42, height: 42)

                            if enemyProjectileKind == 0 {
                                Image("BattleBomb")
                                    .resizable()
                                    .interpolation(.none)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "bomb.fill")
                                    .font(.custom("BoldPixels", size: 26, relativeTo: .title2))
                                    .foregroundStyle(.orange)
                            } else if enemyProjectileKind == 1 {
                                Image(systemName: "snowflake")
                                    .font(.custom("BoldPixels", size: 28, relativeTo: .title))
                                    .foregroundStyle(.cyan)
                            } else if enemyProjectileKind == 2 {
                                Image(systemName: "flame.fill")
                                    .font(.custom("BoldPixels", size: 28, relativeTo: .title))
                                    .foregroundStyle(.red)
                            } else {
                                Image(systemName: "bolt.fill")
                                    .font(.custom("BoldPixels", size: 28, relativeTo: .title))
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .shadow(color: enemyProjectileColor, radius: 10)
                        .zIndex(40)
                        .position(
                            enemyProjectilePoint(
                                progress: bombFlightProgress,
                                canvasSize: proxy.size
                            )
                        )
                    }

                    if lightningWarning {
                        VStack(spacing: 0) {
                            Image(systemName: "bolt.fill")
                                .font(.custom("BoldPixels", size: 54, relativeTo: .largeTitle))
                                .foregroundStyle(.yellow, .white)
                                .shadow(color: .yellow, radius: 18)
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow, .white.opacity(0.2), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 10, height: max(90, proxy.size.height - 300))
                        }
                        .position(
                            x: proxy.size.width * 0.22,
                            y: 80 + lightningProgress * (proxy.size.height - 285 - jumpHeight)
                        )
                        .zIndex(70)
                    }

                    if isFrozen {
                        ZStack {
                            Circle()
                                .fill(.cyan.opacity(0.28))
                                .frame(width: 112, height: 112)
                            Circle()
                                .stroke(.white.opacity(0.9), lineWidth: 4)
                                .frame(width: 104, height: 104)
                            Image(systemName: "snowflake")
                                .font(.custom("BoldPixels", size: 52, relativeTo: .largeTitle))
                                .foregroundStyle(.white, .cyan)
                                .shadow(color: .cyan, radius: 16)
                        }
                        .position(
                            x: proxy.size.width * 0.22,
                            y: proxy.size.height - 133 - jumpHeight
                        )
                        .zIndex(65)
                    }

                    if explosionFlash {
                        ZStack {
                            Circle()
                                .fill(.orange.opacity(0.5))
                                .frame(width: 130, height: 130)
                            Circle()
                                .stroke(.yellow, lineWidth: 7)
                                .frame(width: 118, height: 118)
                            Text("💥")
                                .font(.custom("BoldPixels", size: 58, relativeTo: .largeTitle))
                        }
                        .position(
                            x: proxy.size.width * 0.22,
                            y: proxy.size.height - 133 - jumpHeight
                        )
                        .zIndex(66)
                    }
                }
            }
            .offset(y: -72)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .top) {
            GeometryReader { proxy in
                Color.clear
                    .frame(width: proxy.size.width, height: max(0, proxy.size.height - 110))
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 18)
                            .onEnded { value in
                                if value.translation.height < -18 {
                                    jump()
                                }
                            }
                    )
            }
            .allowsHitTesting(true)
        }
        .overlay(alignment: .topLeading) {
            GeometryReader { proxy in
                if !store.equippedSkills.isEmpty {
                    HStack(spacing: 0) {
                        ForEach(store.equippedSkills) { skill in
                            let activeSeconds = skillActiveRemaining[skill.id] ?? 0
                            let cooldownSeconds = skillCooldownRemaining[skill.id] ?? 0
                            let isActive = activeSeconds > 0
                            let isCoolingDown = cooldownSeconds > 0

                            Button {
                                activateSkill(skill)
                            } label: {
                                VStack(spacing: 3) {
                                    Image(systemName: skill.kind.icon)
                                        .font(.custom("BoldPixels", size: 17, relativeTo: .headline))

                                    Text(skill.kind.rawValue)
                                        .font(.custom("BoldPixels", size: 9, relativeTo: .caption2))
                                        .lineLimit(1)

                                    if isActive {
                                        Text("Active \(activeSeconds)s")
                                            .font(.custom("BoldPixels", size: 8, relativeTo: .caption2))
                                            .foregroundStyle(.yellow)
                                        ProgressView(
                                            value: Double(activeSeconds),
                                            total: Double(skill.duration)
                                        )
                                        .tint(.yellow)
                                    } else if isCoolingDown {
                                        Text("Cooldown \(cooldownSeconds)s")
                                            .font(.custom("BoldPixels", size: 8, relativeTo: .caption2))
                                            .foregroundStyle(.cyan)
                                        ProgressView(
                                            value: Double(cooldownSeconds),
                                            total: Double(5 + skill.level)
                                        )
                                        .tint(.cyan)
                                    } else {
                                        Text("Available")
                                            .font(.custom("BoldPixels", size: 8, relativeTo: .caption2))
                                            .foregroundStyle(.white.opacity(0.72))
                                    }
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 88)
                                .background(
                                    isActive
                                        ? .orange.opacity(0.88)
                                        : isCoolingDown
                                            ? .blue.opacity(0.62)
                                            : .purple.opacity(0.82),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .disabled(battleResult != nil || isActive || isCoolingDown)
                        }
                    }
                    .frame(width: proxy.size.width)
                    .position(x: proxy.size.width * 0.5, y: proxy.size.height - 44)
                    .zIndex(80)
                }

            }
            .allowsHitTesting(true)
        }
        .onTapGesture(count: 1, coordinateSpace: .local) { _ in
            if battleResult != nil {
                isPresented = false
            } else {
                jump()
            }
        }
        .overlay {
            BattleEffectOverlay(
                enemyHit: enemyHitFlash,
                playerHit: playerHitFlash,
                perfectDodge: dodgeFlash,
                isEnraged: isEnemyEnraged,
                accent: enemyTint
            )
            .allowsHitTesting(false)
        }
        .overlay {
            if let battleResult {
                ZStack {
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()

                    BattleResultCard(
                        result: battleResult,
                        fishReward: battleResult == .victory ? fishReward : 0,
                        skillPointReward: battleResult == .victory ? skillPointReward : 0,
                        gemReward: battleResult == .victory ? gemReward : 0
                    ) {
                        if battleResult == .victory {
                            let completedLevel = max(1, level - 1)
                            store.defeatedEnemies += 1
                            store.fish += fishReward
                            store.skillPoints += skillPointReward
                            store.gems += gemReward
                            store.message = "Stage \(completedLevel) complete: \(fishReward) Fish, \(skillPointReward) Skill Points, and \(gemReward) Gems earned."
                        } else {
                            store.message = "Battle lost. No rewards earned."
                        }
                        isPresented = false
                    }
                }
            }
        }
        .task {
            wave = 1
            let difficulty = max(0, level - 1)
            enemyVariant = max(0, ((level - 1) / 2) % 8)
            enemyMaxHP = 420 + difficulty * 60 + enemyVariant * 105
            enemyHP = enemyMaxHP
            enemyCount = level >= 3 && level.isMultiple(of: 2) ? 2 : 1
            secondaryEnemyMaxHP = enemyCount == 2
                ? 280 + difficulty * 45 + enemyVariant * 80
                : 0
            secondaryEnemyHP = 0
            playerMaxHP = max(100, store.finalHealth)
            playerHP = playerMaxHP
            scheduleNextEnemyAttack()
            combatNotice = enemyTrait
            store.pendingSoundEffect = .battleStart
            try? await Task.sleep(nanoseconds: 120_000_000)
            withAnimation(.easeInOut(duration: 0.65)) {
                battleStarted = true
            }
            await battleLoop()
        }
        .preferredColorScheme(.dark)
    }

    private func battleLoop() async {
        while battleResult == nil && !Task.isCancelled {
            let interval = UInt64(max(85, 160 - level * 5)) * 1_000_000
            try? await Task.sleep(nanoseconds: interval)
            guard !Task.isCancelled else { return }
            tick()
        }
    }

    private func tick() {
        guard battleResult == nil else { return }
        tickCount += 1
        distance += 5

        let macInterval = skillRapidFire ? 2 : 5
        if tickCount.isMultiple(of: macInterval) {
            throwMac()
        }

        if enemyHP <= 0, wave < enemyCount {
            wave += 1
            enemyMaxHP = secondaryEnemyMaxHP
            enemyHP = enemyMaxHP
            secondaryEnemyMaxHP = 0
            enemyDodgeOnCooldown = false
            enemyJumpHeight = 0
            combatNotice = "Wave \(wave) enemy appeared"
            return
        }

        // 敵人固定在右側，延遲投擲炸彈反擊玩家。
        if isEnemyEnraged, combatNotice != "⚠️ Enemy enraged" {
            combatNotice = "⚠️ Enemy enraged"
        }
        if tickCount >= nextEnemyAttackTick {
            throwEnemyBomb()
            scheduleNextEnemyAttack()
        }

        if enemyHP <= 0 {
            // 勝利當下就保存下一關，Back to Home或點擊結果卡都會是下一關。
            level = max(2, level + 1)
            battleResult = .victory
            store.pendingSoundEffect = .battleSuccess
        } else if playerHP <= 0 {
            battleResult = .defeat
            store.pendingSoundEffect = .battleFailure
        }
    }

    private func macProjectilePoint(
        progress: CGFloat,
        canvasSize: CGSize
    ) -> CGPoint {
        let trajectoryProgress = min(max(progress, 0), 1)
        let start = CGPoint(
            x: canvasSize.width * macStartX,
            y: canvasSize.height - 123 + macStartYOffset
        )
        let target = CGPoint(
            x: canvasSize.width * macEndX,
            y: canvasSize.height - 123 + macEndYOffset
        )

        // 命中點不是終點；未命中時沿最後斜率繼續飛到畫面邊界。
        if progress > 1 {
            let extraProgress = progress - 1
            return CGPoint(
                x: target.x + (target.x - start.x) * extraProgress,
                y: target.y + (target.y - start.y) * extraProgress
            )
        }

        return CGPoint(
            x: start.x + (target.x - start.x) * trajectoryProgress,
            y: start.y + (target.y - start.y) * trajectoryProgress
        )
    }

    private func enemyProjectilePoint(
        progress: CGFloat,
        canvasSize: CGSize
    ) -> CGPoint {
        let trajectoryProgress = min(max(progress, 0), 1)
        let curveProgress = enemyProjectileType == 1
            ? min(max(progress, 0), 1.42)
            : trajectoryProgress
        let startX = canvasSize.width * bombStartX
        let targetX = canvasSize.width * bombEndX
        let startY = canvasSize.height - 123 + bombStartYOffset
        let targetY = canvasSize.height - 123 + bombEndYOffset
        let horizontalDelta = targetX - startX

        if progress > 1, enemyProjectileType != 1 {
            let extraProgress = progress - 1
            let endSlopeY: CGFloat
            if enemyProjectileType == 2 {
                // 1/x 曲線的最後斜率，讓魔球在接近目標時才明顯上飄。
                let epsilon: CGFloat = 0.08
                let startReciprocal = 1 / (1 + epsilon)
                let endReciprocal = 1 / epsilon
                let reciprocalRange = endReciprocal - startReciprocal
                let endDerivative = 1 / (epsilon * epsilon * reciprocalRange)
                endSlopeY = (targetY - startY) * endDerivative
            } else {
                endSlopeY = targetY - startY
            }
            return CGPoint(
                x: targetX + horizontalDelta * extraProgress,
                y: targetY + endSlopeY * extraProgress
            )
        }

        let y: CGFloat
        if enemyProjectileType == 2 {
            // 反向 1/x：前段變化小，最後接近目標時才快速上飄。
            let epsilon: CGFloat = 0.08
            let reciprocalAtProgress = 1 / (1 - trajectoryProgress + epsilon)
            let startReciprocal = 1 / (1 + epsilon)
            let endReciprocal = 1 / epsilon
            let normalizedReciprocal = (reciprocalAtProgress - startReciprocal)
                / (endReciprocal - startReciprocal)
            y = startY + (targetY - startY) * normalizedReciprocal
        } else {
            // 拋物線在 progress > 1 時仍使用同一條公式，不會突然變成直線。
            y = startY
                + (targetY - startY) * curveProgress
                + enemyProjectileOffset(for: curveProgress)
        }

        return CGPoint(
            x: startX + horizontalDelta * curveProgress,
            y: y
        )
    }

    private func enemyProjectileOffset(for progress: CGFloat) -> CGFloat {
        switch enemyProjectileType {
        case 1:
            // 拋物線球：先上拋，再依同一公式持續下降。
            return -472 * progress * (1 - progress)
        case 2:
            // 上飄魔球由 enemyProjectilePoint() 直接使用正規化 1/x 計算。
            return 0
        default:
            // 直球。
            return 0
        }
    }

    private func scheduleNextEnemyAttack() {
        let variantSpeedBonus = enemyVariant == 5 ? 2 : 0
        let baseInterval = max(3, 8 - level / 5 - variantSpeedBonus)
        let randomVariation = Int.random(in: -2...2)
        let enragedBonus = isEnemyEnraged ? 2 : 0
        let interval = max(2, baseInterval + randomVariation - enragedBonus)
        nextEnemyAttackTick = tickCount + interval
    }

    private var enemyProjectileColor: Color {
        switch enemyProjectileKind {
        case 1: return .cyan
        case 2: return .red
        case 3: return .yellow
        default: return .orange
        }
    }

    private func throwEnemyBomb() {
        guard battleResult == nil, enemyHP > 0, !bombFlying else { return }
        let roll = Int.random(in: 0...3)
        // 高階敵人會偏向使用自己的招牌攻擊。
        enemyProjectileKind = switch enemyVariant {
        case 1:
            roll < 3 ? 1 : roll
        case 2:
            roll < 3 ? 3 : roll
        case 3:
            roll < 3 ? 2 : roll
        case 4:
            roll
        case 5:
            roll == 3 ? 3 : 0
        case 6:
            roll < 3 ? 1 : roll
        case 7:
            Int.random(in: 0...3)
        default:
            roll
        }
        // 敵人在角色下方時，改用必須向上飄升的魔球。
        enemyProjectileType = enemyJumpHeight < jumpHeight - 4
            ? 2
            : Int.random(in: 0...2)
        bombStartX = 0.78
        bombEndX = battleStarted ? 0.22 : 0.5
        bombStartYOffset = -enemyJumpHeight
        bombEndYOffset = -jumpHeight
        bombFlightProgress = 0
        bombFlying = true

        Task { @MainActor in
            // 先給較高初速，再逐幀乘上加速倍率；本體與預測線共用同一個 progress。
            var flightProgress: CGFloat = 0
            let difficultySpeedBonus = CGFloat(max(0, level - 1)) * 0.0018
            let battleSpeedBonus = CGFloat(tickCount) * 0.00012
            var velocity = 0.015 + difficultySpeedBonus + battleSpeedBonus + CGFloat.random(in: 0...0.0025)
            while flightProgress < 1 {
                guard battleResult == nil else { return }
                flightProgress = min(1, flightProgress + velocity)
                bombFlightProgress = flightProgress
                velocity *= 1.035
                try? await Task.sleep(nanoseconds: 16_666_667)
            }

            guard battleResult == nil else { return }
            // The projectile's destination is fixed at launch. A jump after
            // launch moves the player away from that path instead of bending
            // the projectile toward the player.
            let verticalSeparation = abs(bombEndYOffset + jumpHeight)
            if verticalSeparation < 42 {
                let difficulty = max(0, wave - 1)
                let rawDamage = max(25, playerMaxHP / 10 + difficulty * 8)
                let variantMultiplier = enemyVariant == 7 ? 1.4 : enemyVariant == 5 ? 0.9 : 1
                let baseDamage = Int(Double(rawDamage) * variantMultiplier)
                registerPlayerHit()
                bombFlying = false
                bombFlightProgress = 0

                switch enemyProjectileKind {
                case 1:
                    // 冰：每次命中都增加一層凍結時間。
                    let damage = max(12, baseDamage / 2)
                    playerHP = max(0, playerHP - damage)
                    showDamagePopup(damage, isPlayer: true)
                    if !skillControlImmune {
                        freezeStacks += 1
                        isFrozen = true
                    }
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_100_000_000)
                        freezeStacks = max(0, freezeStacks - 1)
                        isFrozen = freezeStacks > 0
                    }
                case 2:
                    // 火焰：每次命中增加一層；每層獨立灼燒三秒，每秒跳一次傷害。
                    let damage = baseDamage
                    playerHP = max(0, playerHP - damage)
                    showDamagePopup(damage, isPlayer: true)
                    burnStacks += 1
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        for _ in 0..<3 {
                            guard battleResult == nil else { return }
                            let burnDamage = max(8, baseDamage / 3)
                            playerHP = max(0, playerHP - burnDamage)
                            showDamagePopup(burnDamage, isPlayer: true)
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                        }
                        burnStacks = max(0, burnStacks - 1)
                    }
                case 3:
                    // 雷電：每次命中都建立一個獨立落雷，不會被其他落雷取消。
                    lightningStrikes += 1
                    lightningWarning = true
                    Task { @MainActor in
                        for frame in 0...12 {
                            lightningProgress = CGFloat(frame) / 12
                            try? await Task.sleep(nanoseconds: 25_000_000)
                        }
                        let damage = baseDamage + 15 + difficulty * 4
                        playerHP = max(0, playerHP - damage)
                        showDamagePopup(damage, isPlayer: true)
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        lightningStrikes = max(0, lightningStrikes - 1)
                        lightningWarning = lightningStrikes > 0
                        lightningProgress = 0
                    }
                default:
                    // 炸彈：每次命中都獨立爆炸。
                    let damage = baseDamage + 25 + difficulty * 6
                    explosionFlash = true
                    playerHP = max(0, playerHP - damage)
                    showDamagePopup(damage, isPlayer: true)
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    explosionFlash = false
                }
            } else {
                registerPerfectDodge()
                // 未命中時保持同一速度模型，直到離開左側畫面邊界。
                while flightProgress < 1.42 {
                    guard battleResult == nil else { return }
                    flightProgress = min(2.0, flightProgress + velocity)
                    bombFlightProgress = flightProgress
                    velocity *= 1.035
                    try? await Task.sleep(nanoseconds: 16_666_667)
                }
                bombFlying = false
                bombFlightProgress = 0
            }
        }
    }

    private func throwMac() {
        guard battleResult == nil,
              (enemyHP > 0 || secondaryEnemyHP > 0),
              !macFlying,
              !isFrozen else { return }
        let isCritical = Double.random(in: 0...1) < store.finalCritRate / 100
        let multiplier = isCritical ? 1 + store.finalCritDamage / 100 : 1
        let skillMultiplier = skillNegativeAttack ? 1.35 : 1.0
        let comboMultiplier = 1 + min(Double(comboCount), 12) * 0.05
        let armorMultiplier = enemyVariant == 6 ? 0.75 : 1
        let damage = max(
            1,
            Int(
                Double(store.finalAttack)
                    * multiplier
                    * skillMultiplier
                    * comboMultiplier
                    * armorMultiplier
                    * 0.25
            )
        )
        // 先鎖定目前仍存活的敵人；第一隻死亡後才瞄準第二隻。
        macTargetIsSecondary = enemyHP <= 0 && secondaryEnemyHP > 0
        let targetX: CGFloat = macTargetIsSecondary ? 0.62 : 0.78
        let targetJumpHeight: CGFloat = macTargetIsSecondary ? 0 : enemyJumpHeight
        macStartX = battleStarted ? 0.22 : 0.5
        macEndX = targetX
        macStartYOffset = -jumpHeight
        macEndYOffset = -targetJumpHeight
        lastDamage = 0
        macFlightProgress = 0
        macFlying = true

        if !macTargetIsSecondary {
            attemptEnemyDodge()
        }

        Task { @MainActor in
            // 先給較高初速，再逐幀乘上加速倍率；Mac 本體與預測線共用同一個 progress。
            var flightProgress: CGFloat = 0
            var velocity: CGFloat = 0.018
            while flightProgress < 1 {
                guard battleResult == nil else { return }
                if isFrozen {
                    macFlying = false
                    macFlightProgress = 0
                    return
                }
                flightProgress = min(1, flightProgress + velocity)
                macFlightProgress = flightProgress
                velocity *= 1.06
                try? await Task.sleep(nanoseconds: 16_666_667)
            }

            guard battleResult == nil else { return }
            if isFrozen {
                macFlying = false
                macFlightProgress = 0
                return
            }
            let targetX: CGFloat = macTargetIsSecondary ? 0.62 : 0.78
            let targetJumpHeight: CGFloat = macTargetIsSecondary ? 0 : enemyJumpHeight
            // 命中判定改用命中當下 Mac 與敵人的實際高度，Mac 沿發射時的高度飛行。
            // Use the projectile's actual target height, rather than the
            // player's current jump height, so hit feedback matches the path.
            let horizontalDistance = abs(macEndX - targetX)
            let verticalDistance = abs(macEndYOffset + targetJumpHeight)
            let hitEnemy = horizontalDistance <= 0.04 && verticalDistance <= 42
            if hitEnemy {
                registerSuccessfulHit(isCritical: isCritical)
                if macTargetIsSecondary {
                    secondaryEnemyHP = max(0, secondaryEnemyHP - damage)
                } else {
                    enemyHP = max(0, enemyHP - damage)
                }
                lastDamage = damage
                showDamagePopup(damage, isPlayer: false)

                try? await Task.sleep(nanoseconds: 180_000_000)
                macFlying = false
                macFlightProgress = 0
            } else {
                comboCount = 0
                combatNotice = "Mac missed. Combo reset."
                // 未命中時保持同一速度模型，直到完整飛出右側畫面。
                while flightProgress < 2.0 {
                    guard battleResult == nil else { return }
                    flightProgress = min(2.0, flightProgress + velocity)
                    macFlightProgress = flightProgress
                    velocity *= 1.06
                    try? await Task.sleep(nanoseconds: 16_666_667)
                }
                macFlying = false
                macFlightProgress = 0
            }
        }
    }


    private func attemptEnemyDodge() {
        guard enemyJumpHeight <= 0, !enemyDodgeOnCooldown, battleResult == nil else { return }

        let dodgeChance = min(0.14 + Double(max(0, level - 1)) * 0.025, 0.4)
        guard Double.random(in: 0...1) < dodgeChance else { return }

        enemyDodgeMotionID += 1
        let motionID = enemyDodgeMotionID
        enemyDodgeOnCooldown = true
        combatNotice = "Enemy dodged Mac"

        Task { @MainActor in
            let frameDuration: UInt64 = 16_666_667
            let timeStep: CGFloat = 1 / 60
            let gravity: CGFloat = 3_200
            var height: CGFloat = 0
            var verticalVelocity = sqrt(2 * gravity * 135)

            while height > 0 || verticalVelocity > 0 {
                guard battleResult == nil, motionID == enemyDodgeMotionID else { return }

                height += verticalVelocity * timeStep
                verticalVelocity -= gravity * timeStep
                enemyJumpHeight = max(0, height)
                try? await Task.sleep(nanoseconds: frameDuration)
            }


            guard motionID == enemyDodgeMotionID else { return }
            enemyJumpHeight = 0
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard motionID == enemyDodgeMotionID else { return }
            enemyDodgeOnCooldown = false

        }
    }

    private func triggerEnemyImpact(isCritical: Bool) {
        enemyHitFlash = true
        let strength: CGFloat = isCritical ? 8 : 4

        withAnimation(.linear(duration: 0.05)) {
            screenShake = strength
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            withAnimation(.linear(duration: 0.05)) {
                screenShake = -strength
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
            withAnimation(.easeOut(duration: 0.08)) {
                screenShake = 0
            }
            try? await Task.sleep(nanoseconds: 240_000_000)
            enemyHitFlash = false
        }
    }

    private func triggerPlayerImpact() {
        playerHitFlash = true
        withAnimation(.linear(duration: 0.05)) {
            screenShake = -7
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 55_000_000)
            withAnimation(.linear(duration: 0.05)) {
                screenShake = 7
            }
            try? await Task.sleep(nanoseconds: 55_000_000)
            withAnimation(.easeOut(duration: 0.1)) {
                screenShake = 0
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
            playerHitFlash = false
        }
    }

    private func registerSuccessfulHit(isCritical: Bool) {
        triggerEnemyImpact(isCritical: isCritical)
        comboCount += 1
        bestCombo = max(bestCombo, comboCount)

        if comboCount.isMultiple(of: 5) {
            let recovery = max(10, playerMaxHP / 20)
            playerHP = min(playerMaxHP, playerHP + recovery)
            combatNotice = "🔥 \(comboCount) Combo! Restored \(recovery) HP"
        } else if isCritical {
            combatNotice = "💥 Critical hit! Combo damage increases"
        } else {
            combatNotice = "Combo ×\(comboCount) · Damage +\(min(comboCount, 12) * 5)%"
        }
    }

    private func showDamagePopup(_ amount: Int, isPlayer: Bool, isHeal: Bool = false) {
        let popup = DamagePopup(amount: amount, isPlayer: isPlayer, isHeal: isHeal)
        damagePopups.append(popup)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            damagePopups.removeAll { $0.id == popup.id }
        }
    }

    private func registerPlayerHit() {
        store.pendingSoundEffect = .playerImpact
        triggerPlayerImpact()
        if comboCount > 0 {
            combatNotice = "Hit taken. \(comboCount)-combo reset."
        } else {
            combatNotice = "Swipe up or tap to jump and dodge"
        }
        comboCount = 0
    }

    private func registerPerfectDodge() {
        dodgeFlash = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 380_000_000)
            dodgeFlash = false
        }
        perfectDodges += 1
        comboCount += 1
        bestCombo = max(bestCombo, comboCount)
        let recovery = max(6, playerMaxHP / 50)
        playerHP = min(playerMaxHP, playerHP + recovery)
        combatNotice = "✨ Perfect Dodge! Restored \(recovery) HP"
    }

    private func activateSkill(_ skill: SkillCard) {
        guard battleResult == nil,
              (skillActiveRemaining[skill.id] ?? 0) == 0,
              (skillCooldownRemaining[skill.id] ?? 0) == 0 else { return }

        let duration = skill.duration
        let cooldown = 5 + skill.level
        skillActiveRemaining[skill.id] = duration
        switch skill.kind {
        case .controlImmunity:
            skillControlImmune = true
        case .negativeAttack:
            skillNegativeAttack = true
        case .regeneration:
            skillRegeneration = true
            playerHP = min(playerMaxHP, playerHP + Int(30 * skill.intensity))
        case .rapidFire:
            skillRapidFire = true
        }

        Task { @MainActor in
            for second in stride(from: duration, through: 1, by: -1) {
                guard battleResult == nil else { return }
                skillActiveRemaining[skill.id] = second

                if skill.kind == .regeneration {
                    playerHP = min(playerMaxHP, playerHP + Int(30 * skill.intensity))
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            guard battleResult == nil else { return }

            switch skill.kind {
            case .controlImmunity:
                skillControlImmune = false
            case .negativeAttack:
                skillNegativeAttack = false
            case .regeneration:
                skillRegeneration = false
            case .rapidFire:
                skillRapidFire = false
            }

            skillActiveRemaining[skill.id] = 0
            skillCooldownRemaining[skill.id] = cooldown

            for second in stride(from: cooldown, through: 1, by: -1) {
                guard battleResult == nil else { return }
                skillCooldownRemaining[skill.id] = second
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            skillCooldownRemaining[skill.id] = 0
        }
    }

    private func jump() {
        guard battleResult == nil, jumpCount < 2, !isFrozen else { return }

        store.pendingSoundEffect = .jump
        jumpCount += 1
        jumpMotionID += 1
        let motionID = jumpMotionID
        let startHeight = jumpHeight
        let boostHeight: CGFloat = jumpCount == 2 ? 120 : 105

        Task { @MainActor in
            let frameDuration: UInt64 = 16_666_667
            let timeStep: CGFloat = 1 / 60
            let gravity: CGFloat = 3_200
            var height = startHeight
            var verticalVelocity = sqrt(2 * gravity * boostHeight)

            // The second jump starts from the character's current height and
            // applies a fresh upward velocity. Each frame then integrates the
            // same gravity used by the on-screen collision height.
            while height > 0 || verticalVelocity > 0 {
                guard battleResult == nil, motionID == jumpMotionID else { return }

                height += verticalVelocity * timeStep
                verticalVelocity -= gravity * timeStep
                jumpHeight = max(0, height)
                try? await Task.sleep(nanoseconds: frameDuration)
            }

            guard motionID == jumpMotionID else { return }
            if height <= 0 {
                jumpHeight = 0
                jumpCount = 0
            }
        }
    }
}

struct EnemyAvatar: View {
    let variant: Int
    let tint: Color
    let symbol: String
    let isEnraged: Bool
    let size: CGFloat

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill((isEnraged ? Color.red : tint).opacity(isPulsing ? 0.08 : 0.24))
                .frame(width: size * 1.35, height: size * 1.35)
                .overlay {
                    Circle()
                        .stroke(
                            isEnraged ? .red : tint,
                            style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                        )
                        .rotationEffect(.degrees(isPulsing ? 180 : 0))
                }
                .shadow(color: isEnraged ? .red : tint, radius: isEnraged ? 18 : 9)

            Image("BattleSlime")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: size, height: size)
                .colorMultiply(isEnraged ? .red : tint)

            Image(systemName: symbol)
                .font(.custom("BoldPixels", size: size * 0.22, relativeTo: .title))
                .foregroundStyle(.white)
                .padding(6)
                .background((isEnraged ? Color.red : tint).opacity(0.9), in: Circle())
                .overlay {
                    Circle().stroke(.white.opacity(0.7), lineWidth: 1)
                }
                .offset(x: size * 0.38, y: -size * 0.36)
        }
        .scaleEffect(isEnraged && isPulsing ? 1.08 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: isEnraged ? 0.35 : 1.4).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .accessibilityLabel("Enemy type \(variant + 1)")
    }
}

struct BattleEffectOverlay: View {
    let enemyHit: Bool
    let playerHit: Bool
    let perfectDodge: Bool
    let isEnraged: Bool
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if isEnraged {
                    RadialGradient(
                        colors: [.red.opacity(0.2), .clear],
                        center: UnitPoint(x: 0.78, y: 0.65),
                        startRadius: 10,
                        endRadius: 150
                    )
                    .blendMode(.plusLighter)
                }

                if enemyHit {
                    BattleBurstEffect(color: .yellow, symbol: "sparkles")
                        .position(x: proxy.size.width * 0.78, y: proxy.size.height - 205)
                }

                if playerHit {
                    Color.red.opacity(0.13)
                        .ignoresSafeArea()
                    BattleBurstEffect(color: .red, symbol: "burst.fill")
                        .position(x: proxy.size.width * 0.22, y: proxy.size.height - 205)
                }

                if perfectDodge {
                    BattleBurstEffect(color: .cyan, symbol: "wind")
                        .position(x: proxy.size.width * 0.22, y: proxy.size.height - 205)

                    Text("PERFECT!")
                        .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                        .foregroundStyle(.white)
                        .shadow(color: .cyan, radius: 12)
                        .position(x: proxy.size.width * 0.22, y: proxy.size.height - 300)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct BattleBurstEffect: View {
    let color: Color
    let symbol: String

    @State private var expanded = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: 5)
                .frame(width: expanded ? 110 : 12, height: expanded ? 110 : 12)
                .opacity(expanded ? 0 : 0.9)

            ForEach(0..<10, id: \.self) { index in
                let angle = Double(index) * 2 * Double.pi / 10
                Image(systemName: symbol)
                    .font(.custom("BoldPixels", size: 11, relativeTo: .caption))
                    .foregroundStyle(color)
                    .offset(
                        x: expanded ? CGFloat(cos(angle)) * 64 : 0,
                        y: expanded ? CGFloat(sin(angle)) * 64 : 0
                    )
                    .opacity(expanded ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.38)) {
                expanded = true
            }
        }
    }
}

struct BattleTapEffect: View {
    let isActive: Bool

    private let rayAngles = [0.0, 45, 90, 135, 180, 225, 270, 315]

    var body: some View {
        ZStack {
            Circle()
                .fill(.cyan.opacity(isActive ? 0.24 : 0))
                .frame(width: 58, height: 58)
                .scaleEffect(isActive ? 1.8 : 0.25)

            Circle()
                .stroke(.white.opacity(isActive ? 0.92 : 0), lineWidth: 3)
                .frame(width: 48, height: 48)
                .scaleEffect(isActive ? 1.4 : 0.2)

            ForEach(rayAngles, id: \.self) { angle in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.white, .cyan.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 38)
                    .offset(y: isActive ? -44 : -12)
                    .rotationEffect(.degrees(angle))
                    .opacity(isActive ? 1 : 0)
            }

            Image(systemName: "sparkles")
                .font(.custom("BoldPixels", size: 26, relativeTo: .title2))
                .foregroundStyle(.white, .cyan)
                .scaleEffect(isActive ? 1 : 0.2)
                .opacity(isActive ? 1 : 0)
        }
        .frame(width: 126, height: 126)
        .shadow(color: .cyan.opacity(0.85), radius: 14)
        .animation(.easeOut(duration: 0.18), value: isActive)
        .allowsHitTesting(false)
    }
}

struct BattleMomentumBar: View {
    let combo: Int
    let perfectDodges: Int

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 12) {
                Label("Combo \(combo)", systemImage: "flame.fill")
                    .foregroundStyle(combo >= 5 ? .orange : .white)

                Label("Dodge \(perfectDodges)", systemImage: "wind")
                    .foregroundStyle(.cyan)
            }

        }
        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.black.opacity(0.48), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Combo \(combo), Dodge \(perfectDodges)")
    }
}

struct BattleStatusHeader: View {
    let level: Int
    let wave: Int
    let totalWaves: Int

    var body: some View {
        levelLabel
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .accessibilityElement(children: .combine)
    }

    private var levelLabel: some View {
        Text("Stage \(level) · Wave \(wave)/\(totalWaves)")
            .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.black.opacity(0.42), in: Capsule())
    }

}

struct GameHomeHeader: View {
    let characterName: String
    let level: Int
    let combatPower: Int
    let isMuted: Bool
    let onLeaderboard: () -> Void
    let onSettings: () -> Void
    let onMusic: () -> Void
    let onToggleMute: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            FantasyPanel {
                VStack(alignment: .leading, spacing: 3) {
                    Text(characterName)
                        .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
                    HStack(spacing: 8) {
                        Label("Lv. \(level)", systemImage: "star.fill")
                        Label(combatPower.formatted(), systemImage: "bolt.shield.fill")
                    }
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.white.opacity(0.74))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 13)
            }
            .frame(height: 76)
            .frame(maxWidth: .infinity)

            Menu {
                Button(action: onLeaderboard) {
                    Label("Combat Power Rankings", systemImage: "bolt.shield.fill")
                }
                Button(action: onSettings) {
                    Label("Account Settings", systemImage: "person.crop.circle.badge.gearshape")
                }
                Button(action: onMusic) {
                    Label("Background Music", systemImage: "music.note.list")
                }
                Button(action: onToggleMute) {
                    Label(isMuted ? "Enable Sound & Music" : "Mute", systemImage: isMuted ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "gearshape.fill")
                    .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
                    .foregroundStyle(Color(red: 0.99, green: 0.78, blue: 0.37))
                    .frame(width: 52, height: 52)
                    .background(.black.opacity(0.38), in: Circle())
                    .overlay { Circle().stroke(.white.opacity(0.32), lineWidth: 1) }
            }
            .accessibilityLabel("Game settings and menu")
        }
    }
}

struct FantasyPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                FantasySprite(sourceRect: CGRect(x: 105, y: 74, width: 82, height: 83))
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .overlay(Color.black.opacity(0.18))
            }
            .clipShape(RoundedRectangle(cornerRadius: 13))
            content
        }
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color(red: 0.94, green: 0.75, blue: 0.41).opacity(0.55), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
    }
}

struct FantasyHealthMeter: View {
    let progress: Double
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                .foregroundStyle(.white.opacity(0.72))
            FantasySprite(sourceRect: dragonBarRect, imageName: "Dragonhpbar")
                .aspectRatio(3.5, contentMode: .fit)
                .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)，\(Int(progress * 100))%")
    }

    private var dragonBarRect: CGRect {
        let index = min(7, max(0, Int(((1 - progress) * 7).rounded())))
        return CGRect(x: index * 112, y: 0, width: 112, height: 32)
    }
}

struct FantasySprite: View {
    let sourceRect: CGRect
    let imageName: String

    init(sourceRect: CGRect, imageName: String = "freefantasy") {
        self.sourceRect = sourceRect
        self.imageName = imageName
    }

    var body: some View {
        if let image = UIImage(named: imageName),
           let cgImage = image.cgImage?.cropping(to: sourceRect) {
            Image(uiImage: UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation))
                .resizable()
        } else {
            Color.black.opacity(0.35)
        }
    }
}

struct BattleHealthBar: View {
    let title: String
    let current: Int
    let maximum: Int
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .frame(width: 74, alignment: .leading)
            ProgressView(value: Double(max(0, current)), total: Double(maximum))
                .tint(color)
            Text("\(max(0, current))/\(maximum)")
                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                .frame(width: 78, alignment: .trailing)
        }
    }
}

struct CompactBattleHealthBar: View {
    let title: String
    let current: Int
    let maximum: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                .lineLimit(1)
            ProgressView(value: Double(max(0, current)), total: Double(maximum))
                .tint(color)
                .frame(width: 142, height: 12)
            Text("\(max(0, current))/\(maximum)")
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .foregroundStyle(.white.opacity(0.82))
        }
    }
}

struct CombatActionButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("BoldPixels", size: 16, relativeTo: .subheadline))
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .background(color.opacity(configuration.isPressed ? 0.5 : 0.85), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ContinuousUpgradeButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var repeatTask: Task<Void, Never>?

    var body: some View {
        Button(action: action, label: label)
            .onLongPressGesture(
                minimumDuration: 0.4,
                pressing: { isPressing in
                    if !isPressing {
                        repeatTask?.cancel()
                        repeatTask = nil
                    }
                },
                perform: startRepeating
            )
            .onDisappear {
                repeatTask?.cancel()
            }
    }

    private func startRepeating() {
        repeatTask?.cancel()
        action()
        repeatTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 140_000_000)
                guard !Task.isCancelled else { return }
                action()
            }
        }
    }
}

struct BattleResultCard: View {
    let result: BattleResult
    let fishReward: Int
    let skillPointReward: Int
    let gemReward: Int
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(result == .victory ? "Victory" : "Defeat")
                .font(.custom("BoldPixels", size: 30, relativeTo: .title))
                .foregroundStyle(result == .victory ? .yellow : .red)
            if result == .victory {
                HStack(spacing: 16) {
                    Label("\(fishReward)", systemImage: "fish.fill")
                        .foregroundStyle(.mint)
                    Label("\(skillPointReward)", systemImage: "bolt.fill")
                        .foregroundStyle(.yellow)
                    Label("\(gemReward)", systemImage: "diamond.fill")
                        .foregroundStyle(.cyan)
                }
                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                Text("Battle rewards received")
                    .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                    .foregroundStyle(.white.opacity(0.72))
            } else {
                Text("No rewards this time")
                    .foregroundStyle(.white.opacity(0.75))
            }
            Button(result == .victory ? "Back to Home" : "Back to Home") {
                action()
            }
            .buttonStyle(CombatActionButtonStyle(color: result == .victory ? .cyan : .gray))
        }
        .padding(28)
        .frame(maxWidth: 320)
        .background(.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(result == .victory ? .yellow.opacity(0.7) : .red.opacity(0.7), lineWidth: 2)
        }
    }
}

struct FoxEye: View {
    let color: Color
    private let navy = Color(red: 0.04, green: 0.10, blue: 0.20)

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 25, height: 31)
            Circle()
                .fill(navy)
                .frame(width: 10, height: 16)
            Circle()
                .fill(.white)
                .frame(width: 6, height: 7)
                .offset(x: -5, y: -7)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct SystemPageHeader: View {
    let section: GameSection
    let characterName: String
    let level: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: section.symbol)
                .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                .foregroundStyle(.cyan)
                .frame(width: 52, height: 52)
                .background(.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(.custom("BoldPixels", size: 28, relativeTo: .title))
                Text(section.subtitle)
                    .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                    .foregroundStyle(.white.opacity(0.64))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(characterName)
                    .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                    .lineLimit(1)
                Text("Lv.\(level)")
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(16)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct BottomNavButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                Text(title)
                    .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
            }
            .foregroundStyle(isSelected ? .cyan : .white.opacity(0.48))
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(
                isSelected ? .cyan.opacity(0.14) : .clear,
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 42)
        .contentShape(Rectangle())
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct GachaTenRevealView: View {
    let items: [Gear]
    let onEquipBest: () -> Void

    @State private var cardsVisible = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .purple.opacity(0.3), Color(red: 0.04, green: 0.08, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("10 Summons")
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .tracking(4)
                        .foregroundStyle(.yellow)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 10
                    ) {
                        ForEach(items) { item in
                            GachaMiniCard(item: item)
                                .opacity(cardsVisible ? 1 : 0)
                                .scaleEffect(cardsVisible ? 1 : 0.7)
                        }
                    }
                    .padding(.horizontal, 14)

                    Text("10 items added to your inventory")
                        .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                        .foregroundStyle(.white.opacity(0.6))

                    Button(action: onEquipBest) {
                        Label("Equip Highest-Star Item", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .purple))
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 22)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) {
                cardsVisible = true
            }
        }
        .presentationDetents([.large])
    }
}

struct GachaMiniCard: View {
    let item: Gear

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: item.slot.symbol)
                .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                .foregroundStyle(item.rarityColor)

            Text(String(repeating: "★", count: item.stars))
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .foregroundStyle(item.rarityColor)

            Text(item.style)
                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                .foregroundStyle(item.rarityColor)
                .lineLimit(1)

            Text(item.mainStat.displayValue)
                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                .foregroundStyle(item.rarityColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 122)
        .background(
            LinearGradient(
                colors: [item.rarityColor.opacity(0.72), .black.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(item.rarityColor.opacity(0.9), lineWidth: 1.5)
        }
    }
}

struct GachaRevealView: View {
    let item: Gear
    let onEquip: () -> Void

    @State private var revealed = false
    @State private var glow = false

    private var rarityColor: Color {
        item.rarityColor
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, rarityColor.opacity(0.38), Color(red: 0.04, green: 0.08, blue: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(rarityColor.opacity(glow ? 0.44 : 0.12))
                    .frame(width: 260, height: 260)
                    .blur(radius: glow ? 18 : 5)

                ForEach(0..<12, id: \.self) { index in
                    Rectangle()
                        .fill(rarityColor.opacity(glow ? 0.48 : 0.08))
                        .frame(width: 2, height: 210)
                        .rotationEffect(.degrees(Double(index) * 30))
                        .scaleEffect(glow ? 1 : 0.5)
                }

                VStack(spacing: 18) {
                    Text(revealed ? "New Gear Acquired" : "Aurora Summon")
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .tracking(4)
                        .foregroundStyle(rarityColor)

                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [rarityColor.opacity(0.85), .black.opacity(0.82)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 220, height: 290)
                            .overlay {
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(rarityColor, lineWidth: 2)
                            }
                            .shadow(color: rarityColor.opacity(0.7), radius: glow ? 28 : 4)

                        VStack(spacing: 14) {
                            Image(systemName: item.slot.symbol)
                                .font(.custom("BoldPixels", size: 58, relativeTo: .largeTitle))
                                .foregroundStyle(item.rarityColor)

                            Text(String(repeating: "★", count: item.stars))
                                .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                                .foregroundStyle(rarityColor)

                            Text(item.style)
                                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
                                .multilineTextAlignment(.center)

                            Text(item.slot.rawValue)
                                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        .rotation3DEffect(
                            .degrees(revealed ? 0 : 90),
                            axis: (x: 0, y: 1, z: 0)
                        )
                        .opacity(revealed ? 1 : 0)
                    }

                    if revealed {
                        VStack(spacing: 6) {
                            Text("Main Stat  \(item.mainStat.type.rawValue) +\(item.mainStat.value.formatted(.number.precision(.fractionLength(1))))")
                                .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                            Text("\(item.subStats.count) Substats · Lv.\(item.level)")
                                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))

                        Button(action: onEquip) {
                            Label("Equip Now", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle(color: rarityColor))
                        .padding(.horizontal, 32)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                glow = true
            }

            Task {
                try? await Task.sleep(nanoseconds: 450_000_000)
                withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                    revealed = true
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct LeaderboardPlaceholder: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.45))
            Text(title)

                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }
}


struct BackpackCategoryButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 7) {

            Image(systemName: icon)
                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
            Text(title)
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct BackpackResourceCard: View {
    let title: String
    let value: String
    let detail: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.white.opacity(0.58))
                Text(value)
                    .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                Text(detail)
                    .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ProfileGearDetailCard: View {
    let item: Gear
    let onDestroy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Gear Details")
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(item.displayName)
                        .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                        .foregroundStyle(item.rarityColor)
                }

                Spacer()

                Button("Discard", role: .destructive, action: onDestroy)
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
            }

            Text("Substats")
                .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))

            if item.subStats.isEmpty {
                Text("No substats unlocked")
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(item.subStats) { stat in
                    HStack {
                        Text(stat.type.rawValue)
                        Spacer()
                        Text(stat.displayValue)
                            .foregroundStyle(item.rarityColor)
                    }
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                }
            }
        }
        .padding(14)
        .background(item.rarityColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.rarityColor.opacity(0.35), lineWidth: 1)
        )
    }
}

struct ProfileGearRow: View {
    let item: Gear
    let isEquipped: Bool
    let onSelect: () -> Void
    let onEquip: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSelect) {
                HStack(spacing: 10) {
                    Image(systemName: item.slot.symbol)
                        .foregroundStyle(item.rarityColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.displayName)
                            .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                            .foregroundStyle(.primary)
                        Text("Lv.\(item.level)/\(item.maxLevel) · \(item.mainStat.type.rawValue) \(item.mainStat.displayValue)")
                            .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                            .foregroundStyle(item.rarityColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            VStack(alignment: .trailing, spacing: 5) {
                Button(isEquipped ? "Equipped" : "Equip", action: onEquip)
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(item.rarityColor)

                Button(item.level >= item.maxLevel ? "Max" : "Upgrade", action: onUpgrade)
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(item.level >= item.maxLevel ? item.rarityColor.opacity(0.35) : item.rarityColor)
                    .disabled(item.level >= item.maxLevel)

                if item.level < item.maxLevel {
                    Text("\(item.upgradeCost.formatted()) Gold")
                        .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct CombatPowerCard: View {
    let value: Int

    var body: some View {
        HStack {
            Image(systemName: "bolt.shield.fill")
                .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 3) {
                Text("Combat Power")
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.white.opacity(0.62))
                Text(value.formatted())
                    .font(.custom("BoldPixels", size: 28, relativeTo: .title))
            }

            Spacer()

            Text("ATK · HP · CRIT")
                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                .foregroundStyle(.yellow.opacity(0.75))
        }
        .padding(16)
        .background(
            LinearGradient(colors: [.yellow.opacity(0.18), .orange.opacity(0.08)], startPoint: .leading, endPoint: .trailing),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }
}

struct AchievementCompletionBanner: View {
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Complete")
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.yellow)
                Text(title)
                    .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
            }
            Spacer()
            Image(systemName: "sparkles")
                .foregroundStyle(.orange)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.black.opacity(0.9), in: Capsule())
        .overlay {
            Capsule()
                .stroke(.yellow.opacity(0.8), lineWidth: 1.5)
        }
        .shadow(color: .yellow.opacity(0.35), radius: 12)
    }
}

struct CombatPowerToast: View {
    let delta: Int

    private var isIncrease: Bool {
        delta > 0
    }

    private var displayColor: Color {
        isIncrease ? .yellow : .red
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(isIncrease ? "Combat Power Up" : "Combat Power Down")
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
            Text(delta > 0 ? "+\(delta.formatted())" : "\(delta.formatted())")
                .font(.custom("BoldPixels", size: 28, relativeTo: .title))
        }
        .foregroundStyle(displayColor)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.black.opacity(0.82), in: Capsule())
        .overlay {
            Capsule()
                .stroke(displayColor.opacity(0.75), lineWidth: 1)
        }
        .shadow(color: displayColor.opacity(0.35), radius: 14)
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let bonus: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .foregroundStyle(.white.opacity(0.58))
            Text(value)
                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
            Text(bonus)
                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ProfileSlotRow: View {
    let slot: GearSlot
    let item: Gear?

    private var displayColor: Color {
        item?.rarityColor ?? slot.accent
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: slot.symbol)
                .foregroundStyle(displayColor)
                .frame(width: 38, height: 38)
                .background(displayColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(slot.rawValue)
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(item?.rarityColor ?? .white.opacity(0.58))
                if let item {
                    Text(item.displayName)
                        .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                    Text("Lv.\(item.level)/\(item.maxLevel) · \(item.mainStat.type.rawValue) \(item.mainStat.displayValue)")
                        .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                        .foregroundStyle(item.rarityColor)
                } else {
                    Text("Not Equipped")
                        .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }

            Spacer()

            if item != nil {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.mint)
            }
        }
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct ResourcePill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                    .foregroundStyle(.white.opacity(0.58))
                Text(value)
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.white.opacity(0.08), in: Capsule())
    }
}

struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                    .foregroundStyle(color)
                Text(title)
                    .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                Text(subtitle)
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.white.opacity(0.58))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

struct GearRow: View {
    let item: Gear
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.slot.symbol)
                .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
                .foregroundStyle(item.rarityColor)
                .frame(width: 42, height: 42)
                .background(item.slot.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                    .foregroundStyle(.primary)
                Text("Lv.\(item.level) · Main Stat \(item.mainStat.type.rawValue)")
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                ContinuousUpgradeButton(action: action) {
                    Text(item.level >= item.maxLevel ? "Max" : "Enhance")
                }
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .disabled(item.level >= item.maxLevel)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(item.slot.accent.opacity(0.18), in: Capsule())

                if item.level < item.maxLevel {
                    Text("\(item.upgradeCost.formatted()) Gold")
                        .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct GearDetailCard: View {
    let item: Gear
    let onDestroy: (() -> Void)?
    let action: () -> Void

    init(item: Gear, onDestroy: (() -> Void)? = nil, action: @escaping () -> Void) {
        self.item = item
        self.onDestroy = onDestroy
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(item.slot.rawValue, systemImage: item.slot.symbol)
                    .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                    .foregroundStyle(item.rarityColor)
                Spacer()
                Text("★".repeating(item.stars))
                    .foregroundStyle(item.rarityColor)
            }

            Text(item.displayName)
                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                .foregroundStyle(.primary)
                .padding(.horizontal, 2)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Lv.\(item.level) / \(item.maxLevel)")
                        .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
                    if item.level < item.maxLevel {
                        Text("Upgrade Cost: \(item.upgradeCost.formatted()) Gold")
                            .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                            .foregroundStyle(.yellow)
                    } else {
                        Text("Max level reached")
                            .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                Spacer()
                ContinuousUpgradeButton(action: action) {
                    Text(item.level >= item.maxLevel ? "Max" : "Upgrade")
                }
                    .disabled(item.level >= item.maxLevel)
                    .buttonStyle(PrimaryButtonStyle(color: item.rarityColor))

                if let onDestroy {
                    Button {
                        onDestroy()
                    } label: {
                        Label("Dismantle", systemImage: "trash")
                    }
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.red.opacity(0.9))
                }
            }

            Divider().overlay(.white.opacity(0.15))

            Text("Main Stat  \(item.mainStat.type.rawValue)  \(item.mainStat.displayValue)")
                .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                ForEach(item.subStats) { stat in
                    Text("• \(stat.type.rawValue) \(stat.displayValue)")
                        .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct ProgressCard: View {
    let title: String
    let value: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
            ProgressView(value: progress)
                .tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PuzzleSizeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .foregroundStyle(isSelected ? .black : .mint)
                .background(isSelected ? .mint : .mint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct FishBurstView: View {
    let reward: Int
    @State private var isBursting = false

    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { index in
                Text(["🐟", "🐠", "🐡", "🦈", "🐙", "🦀", "🐬"][index])
                    .font(.custom("BoldPixels", size: 28, relativeTo: .title))
                    .offset(
                        x: isBursting ? CGFloat(index - 3) * 42 : 0,
                        y: isBursting ? -CGFloat(32 + index * 9) : 0
                    )
                    .rotationEffect(.degrees(isBursting ? Double(index - 3) * 20 : 0))
                    .opacity(isBursting ? 1 : 0.2)
            }

            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.custom("BoldPixels", size: 28, relativeTo: .title))
                    .foregroundStyle(.yellow)
                Text("Fish Leap")
                    .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                Text("+\(reward) Fish")
                    .font(.custom("BoldPixels", size: 20, relativeTo: .title3))
                    .foregroundStyle(.mint)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .scaleEffect(isBursting ? 1 : 0.7)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isBursting = true
            }
        }
    }
}

struct HomeShortcutButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                Text(title)
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
            }
            .foregroundStyle(color)
            .frame(width: 64, height: 64)
            .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct StoreProductCard: View {
    let title: String
    let detail: String
    let price: String
    let icon: String
    let color: Color
    let isFeatured: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                if isFeatured {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Limited Offer")
                            .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                        Spacer()
                        Image(systemName: "crown.fill")
                    }
                    .foregroundStyle(.yellow)
                }

                HStack(spacing: 14) {
                    if isFeatured {
                        ZStack {
                            Circle()
                                .fill(.yellow.opacity(0.2))
                                .frame(width: 76, height: 76)
                            Image(systemName: "sparkles")
                                .font(.custom("BoldPixels", size: 60, relativeTo: .largeTitle))
                                .foregroundStyle(.orange, .yellow)
                            Image(systemName: icon)
                                .font(.custom("BoldPixels", size: 34, relativeTo: .largeTitle))
                                .foregroundStyle(.red, .yellow)
                                .shadow(color: .orange, radius: 8)
                        }
                        .frame(width: 82, height: 82)
                    } else {
                        Image(systemName: icon)
                            .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                            .foregroundStyle(color)
                            .frame(width: 44, height: 44)
                            .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.custom("BoldPixels", size: isFeatured ? 20 : 17, relativeTo: isFeatured ? .title3 : .headline))
                        Text(detail)
                            .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Text(price)
                        .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(color, in: Capsule())
                }
            }
            .padding(isFeatured ? 20 : 16)
            .background(
                isFeatured
                    ? LinearGradient(colors: [.yellow.opacity(0.34), .orange.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [color.opacity(0.1), color.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: isFeatured ? 24 : 18)
            )
            .overlay(
                RoundedRectangle(cornerRadius: isFeatured ? 24 : 18)
                    .stroke(color.opacity(isFeatured ? 0.9 : 0.35), lineWidth: isFeatured ? 2 : 1)
            )
            .shadow(color: isFeatured ? .orange.opacity(0.45) : .clear, radius: 14)
        }
        .buttonStyle(.plain)
    }
}

struct StorePlaceholderCard: View {
    let title: String
    let detail: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.custom("BoldPixels", size: 24, relativeTo: .title2))
                .foregroundStyle(color)
            Text(title)
                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
            Text(detail)
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MinefieldDifficultyButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .foregroundStyle(isSelected ? .black : .cyan)
                .background(isSelected ? .cyan : .cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct MinefieldModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? .black : .cyan)
                .background(isSelected ? .cyan : .cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct MinefieldCellView: View {
    let value: Int
    let isRevealed: Bool
    let isMine: Bool
    let hasFish: Bool
    let isFlagged: Bool
    let gridSize: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(isRevealed ? Color.cyan.opacity(0.13) : Color.white.opacity(0.16))

            if isRevealed {
                if isMine {
                    Image(systemName: "burst.fill")
                        .foregroundStyle(.red)
                } else if hasFish {
                    Image(systemName: "fish.fill")
                        .foregroundStyle(.mint)
                } else if value > 0 {
                    Text("\(value)")
                        .font(.custom("BoldPixels", size: gridSize >= 17 ? 11 : gridSize >= 11 ? 14 : 17, relativeTo: .caption))
                        .foregroundStyle(.yellow)
                } else {
                    Image(systemName: "water.waves")
                        .foregroundStyle(.cyan)
                }
            } else if isFlagged {
                Image(systemName: "flag.fill")
                    .foregroundStyle(.orange)
            } else {
                Image(systemName: "snowflake")
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: gridSize >= 17 ? 28 : gridSize >= 11 ? 36 : 46)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(.white.opacity(isRevealed ? 0.16 : 0.34), lineWidth: 1)
        )
    }
}

struct TalentNode: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
            Text(value)
                .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AchievementRow: View {
    let id: String
    let title: String
    let detail: String
    let progress: Int
    let total: Int
    let reward: Int
    let icon: String
    let isClaimed: Bool
    let action: () -> Void

    private var canClaim: Bool {
        progress >= total && !isClaimed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.custom("BoldPixels", size: 17, relativeTo: .headline))
                    Text(detail).font(.custom("BoldPixels", size: 12, relativeTo: .caption)).foregroundStyle(.white.opacity(0.58))
                }
                Spacer()
                Text("\(reward) Gems")
                    .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                    .foregroundStyle(.cyan)
            }

            ProgressView(value: Double(min(progress, total)), total: Double(total))
                .tint(canClaim ? .yellow : .cyan)

            HStack {
                Text("\(min(progress, total)) / \(total)")
                    .font(.custom("BoldPixels", size: 10, relativeTo: .caption2))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                Button {
                    action()
                } label: {
                    Label(
                        isClaimed ? "Claimed" : canClaim ? "Claim" : "Incomplete",
                        systemImage: isClaimed ? "checkmark.circle.fill" : canClaim ? "gift.fill" : "lock.fill"
                    )
                }
                .font(.custom("BoldPixels", size: 12, relativeTo: .caption))
                .foregroundStyle(canClaim ? .yellow : .white.opacity(0.4))
                .disabled(!canClaim)
            }
        }
        .padding(16)
        .background(
            canClaim ? .yellow.opacity(0.12) : .white.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("BoldPixels", size: 15, relativeTo: .subheadline))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color.opacity(configuration.isPressed ? 0.55 : 0.85), in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private extension String {
    func repeating(_ count: Int) -> String {
        String(repeating: self, count: count)
    }
}

#Preview {
    ContentView()
}

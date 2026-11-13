import SwiftUI

// MARK: - Progress strip (profile, streak, stars, goal, stickers, parents)

struct HomeProgressStrip: View {
    @ObservedObject private var store = ProgressStore.shared
    @State private var showProfiles = false
    @State private var showStickers = false
    @State private var showParents = false
    var compact = false

    var body: some View {
        HStack(spacing: 8) {
            Button { showProfiles = true } label: {
                HStack(spacing: 6) {
                    Text(store.active.avatar).font(.system(size: 26))
                    if !compact {
                        Text(store.active.name).font(DS.font(.headline)).foregroundColor(DS.ink)
                            .lineLimit(1).fixedSize()
                    }
                }
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(Capsule().fill(DS.surface))
            }
            .buttonStyle(KidButtonStyle())
            .accessibilityLabel("Who's playing: \(store.active.name)")

            Spacer(minLength: 0)

            StatPill(icon: "flame.fill", text: "\(store.streak)")
                .accessibilityLabel("\(store.streak) day streak")
            StatPill(icon: "star.fill", text: "\(store.active.points)", color: DS.yellow)
                .accessibilityLabel("\(store.active.points) points")
            Button { showStickers = true } label: {
                ProgressRing(progress: store.goalProgress, color: DS.green, lineWidth: 5) {
                    Image(systemName: store.goalProgress >= 1 ? "checkmark" : "target")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(DS.green)
                }
                .frame(width: 44, height: 44)
                .background(Circle().fill(DS.surface))
            }
            .buttonStyle(KidButtonStyle())
            .accessibilityLabel("Daily goal \(store.today.traced) of \(store.settings.dailyGoal). Open sticker book.")
            Button { showParents = true } label: {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(DS.inkSoft)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DS.surface))
            }
            .buttonStyle(KidButtonStyle())
            .accessibilityLabel("Parents")
        }
        .sheet(isPresented: $showProfiles) { ProfilePickerSheet() }
        .sheet(isPresented: $showStickers) { StickerBookScreen() }
        .fullScreenCover(isPresented: $showParents) { ParentAreaScreen() }
    }
}

// MARK: - Continue learning

struct ContinueLearningCard: View {
    @ObservedObject private var store = ProgressStore.shared

    var body: some View {
        let path = Curriculum.pathItems
        let next = store.nextPathItem ?? path[0]
        let left = max(0, store.settings.dailyGoal - store.today.traced)
        NavigationLink(destination: TracingScreen(items: path, startIndex: path.firstIndex(of: next) ?? 0)) {
            HStack(spacing: 14) {
                Text(next.text)
                    .font(DS.display(46))
                    .foregroundColor(DS.purple)
                    .frame(width: 76, height: 76)
                    .background(Circle().fill(.white))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Continue learning").font(DS.font(.subheadline)).foregroundColor(.white.opacity(0.9))
                    Text("Trace \(next.title)").font(DS.font(.title2)).foregroundColor(.white)
                    Text(left == 0 ? "Daily goal done. Well done!" : "\(left) more today for your goal")
                        .font(DS.font(.footnote, weight: .bold)).foregroundColor(.white.opacity(0.9))
                }
                Spacer(minLength: 0)
                Image(systemName: "play.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(DS.purple)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(.white))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(LinearGradient(colors: [DS.purple, DS.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: DS.purple.opacity(0.35), radius: 0, x: 0, y: 6)
            )
        }
        .buttonStyle(KidButtonStyle())
    }
}

// MARK: - Who's playing?

struct ProfilePickerSheet: View {
    @ObservedObject private var store = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Who's playing?").font(DS.font(.largeTitle)).foregroundColor(DS.ink).padding(.top, 28)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 16)], spacing: 16) {
                ForEach(store.profiles) { p in
                    Button {
                        store.switchTo(p.id)
                        dismiss()
                    } label: {
                        VStack(spacing: 6) {
                            Text(p.avatar).font(.system(size: 64))
                            Text(p.name).font(DS.font(.headline)).foregroundColor(DS.ink).lineLimit(1)
                            Label("\(p.points)", systemImage: "star.fill").font(DS.font(.subheadline)).foregroundColor(DS.inkSoft)
                        }
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .kidCard(p.id == store.active.id ? DS.green.opacity(0.18) : DS.surface)
                        .overlay(RoundedRectangle(cornerRadius: 26).stroke(p.id == store.active.id ? DS.green : .clear, lineWidth: 3))
                    }
                    .buttonStyle(KidButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            Text("Grown-ups can add children in the Parents area")
                .font(DS.font(.footnote, weight: .semibold)).foregroundColor(DS.inkSoft)
            Spacer()
        }
        .background(DS.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Sticker book

struct StickerBookScreen: View {
    @ObservedObject private var store = ProgressStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let earned = store.active.badges
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    Text("Sticker Book").font(DS.font(.largeTitle)).foregroundColor(DS.ink)
                    Spacer()
                    CircleIconButton(systemName: "xmark", color: DS.inkSoft, size: 44, label: "Close") { dismiss() }
                }
                HStack(spacing: 14) {
                    ProgressRing(progress: store.goalProgress, color: DS.green, lineWidth: 10) {
                        VStack(spacing: 0) {
                            Text("\(store.today.traced)/\(store.settings.dailyGoal)").font(DS.font(.title3)).foregroundColor(DS.ink)
                            Text("today").font(DS.font(.caption, weight: .bold)).foregroundColor(DS.inkSoft)
                        }
                    }
                    .frame(width: 96, height: 96)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.goalProgress >= 1 ? "Daily goal reached!" : "Daily goal")
                            .font(DS.font(.title3)).foregroundColor(DS.ink)
                        HStack(spacing: 12) {
                            Label("\(store.streak)-day streak", systemImage: "flame.fill")
                            Label("\(store.totalStars) stars", systemImage: "star.fill")
                        }
                        .font(DS.font(.subheadline, weight: .bold)).foregroundColor(DS.inkSoft)
                        StreakWeek()
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .kidCard()

                Text("\(earned.count) of \(Badge.all.count) stickers")
                    .font(DS.font(.headline)).foregroundColor(DS.inkSoft)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 14)], spacing: 14) {
                    ForEach(Badge.all) { b in
                        let has = earned[b.id] != nil
                        VStack(spacing: 6) {
                            Group {
                                if has {
                                    Text(b.emoji).font(.system(size: 52))
                                } else {
                                    Image(systemName: "lock.fill").font(.system(size: 34, weight: .bold))
                                        .foregroundColor(DS.inkSoft.opacity(0.5))
                                        .frame(height: 62)
                                }
                            }
                            Text(b.title).font(DS.font(.headline)).foregroundColor(DS.ink)
                                .multilineTextAlignment(.center)
                            Text(b.detail).font(DS.font(.caption, weight: .semibold)).foregroundColor(DS.inkSoft)
                                .multilineTextAlignment(.center)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 170)
                        .kidCard(has ? DS.yellow.opacity(0.18) : DS.surface)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(b.title), \(has ? "earned" : "locked"). \(b.detail)")
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .background(DS.background.ignoresSafeArea())
    }
}

/// Seven dots for this week's practice days.
struct StreakWeek: View {
    @ObservedObject private var store = ProgressStore.shared
    var body: some View {
        HStack(spacing: 6) {
            ForEach(store.recentDays(7), id: \.date) { day in
                let active = day.record.traced > 0 || day.record.seconds >= 60
                VStack(spacing: 2) {
                    Circle().fill(active ? DS.orange : DS.inkSoft.opacity(0.2)).frame(width: 18, height: 18)
                        .overlay(Image(systemName: "flame.fill").font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white).opacity(active ? 1 : 0))
                    Text(day.date.formatted(.dateTime.weekday(.narrow)))
                        .font(DS.font(.caption2, weight: .bold)).foregroundColor(DS.inkSoft)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Practice this week")
    }
}

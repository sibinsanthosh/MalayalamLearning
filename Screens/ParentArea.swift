import Charts
import SwiftUI

/// Grown-ups only: a multiplication gate, then the dashboard, settings and profiles.
struct ParentAreaScreen: View {
    @State private var unlocked = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if unlocked {
                    ParentDashboard()
                } else {
                    ParentGate { withAnimation { unlocked = true } }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }.font(DS.font(.headline))
                }
            }
        }
    }
}

// MARK: - Gate

struct ParentGate: View {
    let onPass: () -> Void
    @State private var a = Int.random(in: 3...9)
    @State private var b = Int.random(in: 4...9)
    @State private var answer = ""
    @State private var shake = 0

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "lock.shield.fill").font(.system(size: 54)).foregroundColor(DS.purple)
            Text("For grown-ups").font(DS.font(.largeTitle)).foregroundColor(DS.ink)
            Text("What is \(a) × \(b)?").font(DS.font(.title2, weight: .bold)).foregroundColor(DS.inkSoft)
            Text(answer.isEmpty ? " " : answer)
                .font(DS.display(44)).foregroundColor(DS.ink)
                .frame(width: 180, height: 70)
                .kidCard(DS.surface, radius: 20)
                .modifier(Shake(animatableData: CGFloat(shake)))
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(84), spacing: 12), count: 3), spacing: 12) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "✓"], id: \.self) { key in
                    Button { press(key) } label: {
                        Text(key).font(DS.font(.title))
                            .foregroundColor(key == "✓" ? .white : DS.ink)
                            .frame(width: 84, height: 64)
                            .background(RoundedRectangle(cornerRadius: 18).fill(key == "✓" ? DS.green : DS.surface))
                    }
                    .buttonStyle(KidButtonStyle())
                    .accessibilityLabel(key == "⌫" ? "Delete" : (key == "✓" ? "Check" : key))
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(DS.background.ignoresSafeArea())
    }

    private func press(_ key: String) {
        switch key {
        case "⌫": if !answer.isEmpty { answer.removeLast() }
        case "✓":
            if Int(answer) == a * b {
                onPass()
            } else {
                withAnimation(.default) { shake += 1 }
                answer = ""
                a = Int.random(in: 3...9)
                b = Int.random(in: 4...9)
            }
        default: if answer.count < 3 { answer += key }
        }
    }
}

// MARK: - Dashboard

struct ParentDashboard: View {
    @ObservedObject private var store = ProgressStore.shared
    @State private var editing: ChildProfile?
    @State private var adding = false
    @State private var confirmReset = false

    var body: some View {
        Form {
            Section {
                Picker("Child", selection: Binding(get: { store.active.id }, set: { store.switchTo($0) })) {
                    ForEach(store.profiles) { p in Text("\(p.avatar) \(p.name)").tag(p.id) }
                }
            }

            Section("Progress") {
                let letters = Curriculum.letters
                statRow("Letters traced", "\(store.tracedCount(of: letters)) / \(letters.count)")
                statRow("Vowel-sign letters", "\(store.active.records.keys.filter { $0.unicodeScalars.count == 2 }.count)")
                statRow("Stars earned", "\(store.totalStars)")
                statRow("Current streak", "\(store.streak) days")
                statRow("Stickers", "\(store.active.badges.count) / \(Badge.all.count)")
                statRow("Games finished", "\(store.active.gamesFinished)")
                statRow("Stories finished", "\(store.active.storiesRead.count) / \(DataRepository.shared.stories.count)")
            }

            Section("Time spent (last 7 days)") {
                let days = store.recentDays(7)
                Chart(days, id: \.date) { day in
                    BarMark(x: .value("Day", day.date, unit: .day),
                            y: .value("Minutes", Double(day.record.seconds) / 60))
                        .foregroundStyle(DS.purple.gradient)
                        .cornerRadius(6)
                }
                .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.abbreviated)) } }
                .frame(height: 180)
                .padding(.vertical, 8)
                let total = days.reduce(0) { $0 + $1.record.seconds } / 60
                Text("\(total) minutes this week • \(store.today.seconds / 60) min today")
                    .foregroundColor(.secondary)
            }

            Section("Needs practice") {
                let weak = store.needsPractice(from: Curriculum.allItems, limit: 10)
                if weak.isEmpty {
                    Text("Nothing yet — letters with low stars or many slips will show here.").foregroundColor(.secondary)
                } else {
                    ForEach(weak) { item in
                        let r = store.record(for: item.id)
                        HStack {
                            Text(item.text).font(DS.display(28)).frame(width: 56)
                            VStack(alignment: .leading) {
                                Text(item.title).font(.headline)
                                Text(String(format: "Best %d★ • %.1f slips per try • %d tries", r.bestStars, r.averageSlips, r.completions))
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Mastered (3 stars)") {
                let mastered = Curriculum.allItems.filter { store.stars(for: $0.id) == 3 }
                if mastered.isEmpty {
                    Text("No 3-star letters yet.").foregroundColor(.secondary)
                } else {
                    Text(mastered.map(\.text).joined(separator: "  ")).font(DS.display(26))
                }
            }

            Section("Settings") {
                Toggle("Sounds & voice", isOn: $store.settings.soundOn)
                Toggle("Vibration", isOn: $store.settings.hapticsOn)
                Toggle("Show tracing hints (demo finger)", isOn: $store.settings.showHints)
                Toggle("Left-handed layout", isOn: $store.settings.leftHanded)
                Stepper("Daily goal: \(store.settings.dailyGoal) letters", value: $store.settings.dailyGoal, in: 1...15)
            }

            Section("Children") {
                ForEach(store.profiles) { p in
                    Button { editing = p } label: {
                        HStack {
                            Text(p.avatar).font(.title)
                            Text(p.name).foregroundColor(.primary)
                            Spacer()
                            if p.id == store.active.id { Text("Playing").font(.caption).foregroundColor(.green) }
                        }
                    }
                }
                Button { adding = true } label: { Label("Add a child", systemImage: "plus.circle.fill") }
                Button("Reset \(store.active.name)'s progress", role: .destructive) { confirmReset = true }
            }

            Section("Share") {
                ShareLink(item: URL(string: "https://apps.apple.com/in/app/learn-malayalam-easy/id6759353287")!) {
                    Label("Share this app with friends", systemImage: "square.and.arrow.up")
                }
            }

            Section {
                Text("All progress stays on this device. Ads shown in the app are limited to child-directed, general-audience ads.")
                    .font(.footnote).foregroundColor(.secondary)
            }
        }
        .navigationTitle("Parents")
        .sheet(item: $editing) { p in ProfileEditor(profile: p) }
        .sheet(isPresented: $adding) { ProfileEditor(profile: nil) }
        .confirmationDialog("Reset all progress for \(store.active.name)? This can't be undone.",
                            isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset progress", role: .destructive) { store.resetProgress(store.active.id) }
        }
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundColor(.secondary).monospacedDigit()
        }
    }
}

// MARK: - Profile editor

struct ProfileEditor: View {
    let profile: ChildProfile?
    @ObservedObject private var store = ProgressStore.shared
    @State private var name = ""
    @State private var avatar = "🐘"
    @State private var confirmDelete = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Child's name", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section("Avatar") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(ProgressStore.avatars, id: \.self) { a in
                            Button { avatar = a } label: {
                                Text(a).font(.system(size: 34))
                                    .frame(width: 48, height: 48)
                                    .background(Circle().fill(a == avatar ? DS.green.opacity(0.3) : .clear))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if let profile, store.profiles.count > 1 {
                    Section {
                        Button("Delete \(profile.name)", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(profile == nil ? "Add a child" : "Edit child")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let profile {
                            store.updateProfile(profile.id, name: name, avatar: avatar)
                        } else {
                            store.addProfile(name: name, avatar: avatar)
                        }
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Delete this child and all their progress?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let profile { store.deleteProfile(profile.id) }
                    dismiss()
                }
            }
            .onAppear {
                name = profile?.name ?? ""
                avatar = profile?.avatar ?? ProgressStore.avatars.randomElement()!
            }
        }
    }
}

/// Horizontal wiggle used for a wrong answer.
struct Shake: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 4), y: 0))
    }
}

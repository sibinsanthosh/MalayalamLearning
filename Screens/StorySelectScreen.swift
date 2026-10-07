import SwiftUI

struct StorySelectScreen: View {
    @ObservedObject var viewModel: MainViewModel

    @Environment(\.horizontalSizeClass) private var hSizeClass
    
    // Colorful gradient combinations for the list items
    let cardGradients = [
        [Color(hex: "FF9A9E"), Color(hex: "FECFEF")],
        [Color(hex: "84FAB0"), Color(hex: "8FD3F4")],
        [Color(hex: "A18CD1"), Color(hex: "FBC2EB")],
        [Color(hex: "FFD194"), Color(hex: "70E1F5")],
        [Color(hex: "F6D365"), Color(hex: "FDA085")]
    ]

    // 2-column grid used on iPad
    private let gridColumns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        if hSizeClass == .regular {
            IPadStorySelectView(viewModel: viewModel)
        } else {
            iPhoneStorySelectView
        }
    }

    private var iPhoneStorySelectView: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "FFFDE7"), Color(hex: "E0F7FA")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Array(viewModel.stories.enumerated()), id: \.element.id) { index, story in
                        NavigationLink(destination: LazyView { StoryDetailScreen(story: story) }) {
                            StoryListRow(
                                story: story,
                                colors: cardGradients[index % cardGradients.count]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Stories")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ==========================================
// MARK: - IPAD 3-COLUMN BOOKSHELF VIEW
// MARK: - ==========================================

struct IPadStorySelectView: View {
    @ObservedObject var viewModel: MainViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]
    
    var body: some View {
        ZStack {
            // Warm library background
            LinearGradient(
                colors: [Color(hex: "FFF9E6"), Color(hex: "E8F4F8")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Storybook Library • കഥാ ലോകം")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(Color(hex: "3E2723"))
                            Text("Read engaging Malayalam illustrated moral stories with bilingual text")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "6D4C41"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    // 3-Column Illustrated Bookshelf
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(Array(viewModel.stories.enumerated()), id: \.element.id) { index, story in
                            NavigationLink(destination: LazyView { StoryDetailScreen(story: story) }) {
                                IPadStoryBookCard(story: story, index: index)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Storybook Library")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IPadStoryBookCard: View {
    let story: Story
    let index: Int
    
    let badgeGradients = [
        [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
        [Color(hex: "4E65FF"), Color(hex: "92EFFD")],
        [Color(hex: "11998E"), Color(hex: "38EF7D")],
        [Color(hex: "FC466B"), Color(hex: "3F5EFB")],
        [Color(hex: "F9D423"), Color(hex: "FF4E50")]
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Book Cover Image
            ZStack(alignment: .topTrailing) {
                if UIImage(named: story.coverImageName) != nil {
                    Image(story.coverImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                } else {
                    ZStack {
                        Color(hex: "FFE0B2")
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "FF9800").opacity(0.6))
                    }
                    .frame(height: 200)
                }
                
                // Page count tag
                Text("\(story.pages.count) PAGES")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(12)
                    .padding(12)
            }
            
            // Book Details
            VStack(alignment: .leading, spacing: 8) {
                Text(story.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "2D2D2D"))
                    .lineLimit(1)
                
                Text(story.titleEn)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer(minLength: 12)
                
                // Read Action Button
                HStack {
                    Text("Read Story")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: badgeGradients[index % badgeGradients.count],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            .padding(16)
            .background(Color.white)
        }
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}



struct StoryListRow: View {
    let story: Story
    let colors: [Color]
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "book.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 6) {
                Text(story.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(story.titleEn)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.8))
                .font(.system(size: 20, weight: .bold))
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: colors[1].opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

// A helper view to delay the instantiation of the destination screen
struct LazyView<Content: View>: View {
    let build: () -> Content
    var body: Content {
        build()
    }
}

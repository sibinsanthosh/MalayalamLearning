import SwiftUI

struct TracingScreen: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var currentLetter: Letter
    
    @State private var paths: [Path] = []
    @State private var currentPath = Path()
    @State private var progress: CGFloat = 0.0
    @State private var showSuccess = false
    
    // Tracing verification state
    @State private var visitedQuadrants = Set<Int>()
    @State private var totalDistance: CGFloat = 0.0
    @State private var lastPoint: CGPoint? = nil
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass

    init(viewModel: MainViewModel, letter: Letter) {
        self.viewModel = viewModel
        self._currentLetter = State(initialValue: letter)
    }
    
    private var nextLetter: Letter? {
        let list = currentLetter.category == "vowel" ? viewModel.vowels : viewModel.consonants
        if let idx = list.firstIndex(where: { $0.id == currentLetter.id }), idx + 1 < list.count {
            return list[idx + 1]
        }
        return nil
    }

    /// Max width for the tracing UI column on iPad
    private var tracingMaxWidth: CGFloat {
        hSizeClass == .regular ? 600 : .infinity
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F8F8F5").ignoresSafeArea()
            
            // Centre the whole tracing column on iPad
            HStack {
                Spacer()
                VStack {
                    // Header
                    Text(currentLetter.char)
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                        .padding(.top)
                    
                    // Progress
                    HStack {
                        Text("Tracing")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding(.horizontal)
                    
                    // Canvas
                    GeometryReader { geometry in
                        ZStack {
                            // Guide Letter (Dotted)
                            Text(currentLetter.char)
                                .font(.system(size: 1000, weight: .bold))
                                .minimumScaleFactor(0.01)
                                .lineLimit(1)
                                .foregroundColor(.gray.opacity(0.3))
                                .frame(width: geometry.size.width * 0.94, height: geometry.size.height * 0.88)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            
                            // User Drawing
                            Canvas { context, size in
                                for path in paths {
                                    context.stroke(path, with: .color(.blue), lineWidth: 10)
                                }
                                context.stroke(currentPath, with: .color(.blue), lineWidth: 10)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let newPoint = value.location
                                        
                                        let width = geometry.size.width
                                        let height = geometry.size.height
                                        let centerX = width / 2
                                        let centerY = height / 2
                                        
                                        // Bounding Box / Active Area Check (ignore margin scribbles)
                                        let minX = width * 0.03
                                        let maxX = width * 0.97
                                        let minY = height * 0.03
                                        let maxY = height * 0.97
                                        
                                        guard newPoint.x >= minX && newPoint.x <= maxX &&
                                              newPoint.y >= minY && newPoint.y <= maxY else {
                                            return
                                        }
                                        
                                        // Add to current path
                                        if currentPath.isEmpty {
                                            currentPath.move(to: newPoint)
                                            lastPoint = newPoint
                                        } else {
                                            currentPath.addLine(to: newPoint)
                                            
                                            // Track drawing distance
                                            if let last = lastPoint {
                                                let dist = sqrt(pow(newPoint.x - last.x, 2) + pow(newPoint.y - last.y, 2))
                                                totalDistance += dist
                                            }
                                            lastPoint = newPoint
                                        }
                                        
                                        // Track quadrant coverage
                                        let quad: Int
                                        if newPoint.x < centerX {
                                            quad = newPoint.y < centerY ? 1 : 3
                                        } else {
                                            quad = newPoint.y < centerY ? 2 : 4
                                        }
                                        visitedQuadrants.insert(quad)
                                        
                                        // Calculate progress (require both spatial coverage and minimum line length)
                                        let targetDistance = (width + height) * 1.1
                                        let distanceRatio = min(totalDistance / targetDistance, 1.0)
                                        let quadrantRatio = CGFloat(visitedQuadrants.count) / 4.0
                                        
                                        progress = distanceRatio * quadrantRatio
                                    }
                                    .onEnded { _ in
                                        paths.append(currentPath)
                                        currentPath = Path()
                                        lastPoint = nil
                                        
                                        // Only complete if they actually cover >= 95% of the quadrant + length check
                                        if progress >= 0.95 {
                                            progress = 1.0 // snap to 100%
                                            viewModel.addPoints(10)
                                            showSuccess = true
                                        }
                                    }
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 2)
                        .padding()
                    }
                    
                    Button(action: {
                        paths = []
                        currentPath = Path()
                        progress = 0
                        visitedQuadrants.removeAll()
                        totalDistance = 0.0
                        lastPoint = nil
                        showSuccess = false
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                            .padding()
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text(showSuccess ? "Done (+10 pts)" : "Trace to Finish")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(showSuccess ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!showSuccess)
                    .padding()
                }
                .frame(maxWidth: tracingMaxWidth)
                Spacer()
            }
            
            if showSuccess {
                SuccessOverlay(
                    hasNext: nextLetter != nil,
                    onNext: {
                        if let next = nextLetter {
                            currentLetter = next
                            paths = []
                            currentPath = Path()
                            progress = 0
                            visitedQuadrants.removeAll()
                            totalDistance = 0.0
                            lastPoint = nil
                            showSuccess = false
                        }
                    },
                    onBack: {
                        dismiss()
                    }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct SuccessOverlay: View {
    @State private var scale: CGFloat = 0.5
    let hasNext: Bool
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            Color.white.opacity(0.95).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Text("🎉 Great Job!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.blue)
                    .scaleEffect(scale)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            scale = 1.0
                        }
                    }
                
                Text("You traced it perfectly!")
                    .font(.title3)
                    .foregroundColor(.gray)
                
                Spacer()
                
                VStack(spacing: 16) {
                    if hasNext {
                        Button(action: onNext) {
                            Text("Next Letter")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.blue)
                                .cornerRadius(16)
                                .shadow(radius: 4)
                        }
                    }
                    
                    Button(action: onBack) {
                        Text("Back to Letters")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
    }
}

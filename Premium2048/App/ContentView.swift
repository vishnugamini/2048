import SwiftUI

struct ContentView: View {
    private enum Screen {
        case menu
        case game
    }

    @StateObject private var viewModel = GameViewModel()
    @State private var screen: Screen = .menu

    var body: some View {
        ZStack {
            backgroundLayer

            switch screen {
            case .menu:
                menuScreen
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
            case .game:
                gameScreen
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .animation(.spring(response: 0.34, dampingFraction: 0.88), value: screen)
        .sheet(isPresented: $viewModel.showingSettings) {
            settingsSheet
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.showingStats) {
            statsSheet
                .presentationDetents([.medium])
        }
        .overlay {
            if let overlay = viewModel.overlayState, screen == .game {
                overlayView(for: overlay)
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.10, blue: 0.18),
                    Color(red: 0.08, green: 0.19, blue: 0.31),
                    Color(red: 0.11, green: 0.27, blue: 0.39),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.white.opacity(0.11))
                .blur(radius: 80)
                .frame(width: 280, height: 280)
                .offset(x: -130, y: -290)

            Circle()
                .fill(PremiumTheme.accent.opacity(0.16))
                .blur(radius: 110)
                .frame(width: 320, height: 320)
                .offset(x: 150, y: 280)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 230, height: 620)
                .blur(radius: 40)
                .rotationEffect(.degrees(24))
                .offset(x: 165, y: -90)
        }
        .ignoresSafeArea()
    }

    private var menuScreen: some View {
        GeometryReader { proxy in
            let sidePadding: CGFloat = 24
            let previewSize = min(proxy.size.width - (sidePadding * 2), 330)

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: proxy.safeAreaInsets.top + 26)

                VStack(alignment: .leading, spacing: 18) {
                    Text("2048")
                        .font(.system(size: 62, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("A premium take on the classic puzzle.")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.90))

                    Text("Smooth motion, full-screen focus, and instant access to a new run or your current board.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, sidePadding)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 22)

                BoardView(board: viewModel.board)
                    .frame(width: previewSize, height: previewSize)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .bottomTrailing) {
                        Text("Best \(viewModel.bestScore)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(18)
                    }

                Spacer(minLength: 22)

                VStack(spacing: 14) {
                    primaryButton(title: "New Game", systemImage: "sparkles") {
                        viewModel.startNewGame()
                        screen = .game
                    }

                    primaryButton(title: "Continue Game", systemImage: "play.fill") {
                        screen = .game
                    }
                    .opacity(viewModel.continueGameAvailable() ? 1 : 0.45)
                    .disabled(!viewModel.continueGameAvailable())

                    HStack(spacing: 12) {
                        secondaryButton(title: "Stats", systemImage: "chart.bar.fill") {
                            viewModel.showingStats = true
                        }
                        secondaryButton(title: "Settings", systemImage: "slider.horizontal.3") {
                            viewModel.showingSettings = true
                        }
                    }
                }
                .padding(.horizontal, sidePadding)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 26))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var gameScreen: some View {
        GeometryReader { proxy in
            let sidePadding: CGFloat = 20
            let safeTop = proxy.safeAreaInsets.top
            let safeBottom = max(proxy.safeAreaInsets.bottom, 16)
            let width = proxy.size.width - (sidePadding * 2)
            let availableHeight = proxy.size.height - safeTop - safeBottom - 212
            let boardSize = min(width, max(280, availableHeight))

            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("2048")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Full-screen play.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.68))
                        }

                        Spacer(minLength: 12)

                        HStack(spacing: 12) {
                            statPill(title: "Score", value: "\(viewModel.score)")
                            statPill(title: "Best", value: "\(viewModel.bestScore)")
                        }
                        .frame(maxWidth: 270)
                    }

                    HStack(spacing: 12) {
                        secondaryButton(title: "Menu", systemImage: "chevron.left") {
                            viewModel.abandonCurrentGame()
                            screen = .menu
                        }
                        secondaryButton(title: "Stats", systemImage: "chart.bar.fill") {
                            viewModel.showingStats = true
                        }
                        secondaryButton(title: "Settings", systemImage: "slider.horizontal.3") {
                            viewModel.showingSettings = true
                        }
                    }
                }
                .padding(.horizontal, sidePadding)
                .padding(.top, safeTop + 8)

                Spacer(minLength: 14)

                BoardView(board: viewModel.board)
                    .frame(width: boardSize, height: boardSize)
                    .frame(maxWidth: .infinity)
                    .gesture(
                        DragGesture(minimumDistance: 18)
                            .onEnded(handleDrag)
                    )

                Spacer(minLength: 18)

                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        miniStat(title: "Highest", value: "\(viewModel.highestTile)")
                        miniStat(title: "Games", value: "\(viewModel.stats.gamesPlayed)")
                        miniStat(title: "Moves", value: "\(viewModel.stats.totalMoves)")
                    }

                    primaryButton(title: "New Game", systemImage: "arrow.clockwise") {
                        viewModel.startNewGame()
                    }

                    Text("Swipe across the board to move the tiles.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.66))
                }
                .padding(.horizontal, sidePadding)
                .padding(.bottom, safeBottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.58))
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.11), lineWidth: 1)
        )
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.58))
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func primaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.90, green: 0.95, blue: 1.0),
                    PremiumTheme.accent,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)
    }

    private func secondaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.11), lineWidth: 1)
        )
    }

    private func overlayView(for overlay: GameViewModel.OverlayState) -> some View {
        ZStack {
            Color.black.opacity(0.34).ignoresSafeArea()

            VStack(spacing: 14) {
                Text(overlay == .victory ? "2048 Reached" : "No More Moves")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(overlay == .victory ? "You made it. Start fresh or head back to the menu." : "This run is over. Start another or return to the menu.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.white.opacity(0.72))

                HStack(spacing: 12) {
                    secondaryButton(title: "Menu", systemImage: "house") {
                        viewModel.dismissOverlay()
                        viewModel.abandonCurrentGame()
                        screen = .menu
                    }
                    primaryButton(title: "New Game", systemImage: "arrow.clockwise") {
                        viewModel.startNewGame()
                    }
                }
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            )
            .padding(.horizontal, 28)
        }
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Toggle("Sound", isOn: Binding(
                    get: { viewModel.settings.soundEnabled },
                    set: {
                        viewModel.settings.soundEnabled = $0
                        viewModel.saveSettings()
                    }
                ))
                Toggle("Haptics", isOn: Binding(
                    get: { viewModel.settings.hapticsEnabled },
                    set: {
                        viewModel.settings.hapticsEnabled = $0
                        viewModel.saveSettings()
                    }
                ))
            }
            .navigationTitle("Settings")
        }
    }

    private var statsSheet: some View {
        NavigationStack {
            List {
                statRow(title: "Best Score", value: "\(viewModel.bestScore)")
                statRow(title: "Highest Tile", value: "\(viewModel.highestTile)")
                statRow(title: "Games Played", value: "\(viewModel.stats.gamesPlayed)")
                statRow(title: "Total Moves", value: "\(viewModel.stats.totalMoves)")
            }
            .navigationTitle("Stats")
        }
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    private func handleDrag(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height

        if abs(horizontal) > abs(vertical) {
            viewModel.handleSwipe(horizontal > 0 ? .right : .left)
        } else {
            viewModel.handleSwipe(vertical > 0 ? .down : .up)
        }
    }
}

#Preview {
    ContentView()
}

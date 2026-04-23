import SwiftUI

struct ContentView: View {
    private enum Screen {
        case menu
        case game
    }

    @StateObject private var viewModel = GameViewModel()
    @State private var screen: Screen = .menu
    @State private var showingGameMenu = false

    private var palette: PremiumPalette {
        PremiumTheme.palette(for: viewModel.settings.selectedTheme)
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics(proxy: proxy)

            ZStack {
                backgroundLayer(metrics: metrics)
                    .ignoresSafeArea()

                switch screen {
                case .menu:
                    menuScreen(metrics: metrics)
                case .game:
                    gameScreen(metrics: metrics)
                }

                if let overlay = viewModel.overlayState, screen == .game {
                    overlayView(for: overlay, metrics: metrics)
                }

                if let achievement = viewModel.achievementBanner {
                    achievementToast(achievement: achievement, metrics: metrics)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            settingsSheet
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showingStats) {
            statsSheet
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showingHowToPlay) {
            howToPlaySheet
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingGameMenu) {
            gameMenuSheet
                .presentationDetents([.medium, .large])
        }
    }

    private func backgroundLayer(metrics: LayoutMetrics) -> some View {
        ZStack {
            palette.backgroundGradient

            Circle()
                .fill(palette.glow.opacity(0.22))
                .frame(width: metrics.safeWidth * 0.72, height: metrics.safeWidth * 0.72)
                .blur(radius: 90)
                .offset(x: metrics.safeWidth * 0.32, y: -metrics.safeHeight * 0.26)

            Circle()
                .fill(palette.accentSecondary.opacity(0.16))
                .frame(width: metrics.safeWidth * 0.80, height: metrics.safeWidth * 0.80)
                .blur(radius: 120)
                .offset(x: -metrics.safeWidth * 0.28, y: metrics.safeHeight * 0.22)

            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .frame(width: metrics.safeWidth * 0.42, height: metrics.safeHeight * 0.92)
                .blur(radius: 56)
                .rotationEffect(.degrees(18))
                .offset(x: metrics.safeWidth * 0.34, y: 0)
        }
    }

    private func menuScreen(metrics: LayoutMetrics) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: metrics.sectionGap) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PREMIUM")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(palette.textSecondary)
                                .tracking(3)

                            Text("2048")
                                .font(.system(size: metrics.heroTitleSize, weight: .black, design: .rounded))
                                .foregroundStyle(palette.heroGradient)

                            Text("Arcade-polished puzzle flow with tactile motion, smart assists, and a board that feels alive.")
                                .font(.system(size: metrics.bodySize, weight: .medium, design: .rounded))
                                .foregroundStyle(palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 16)

                        scoreOrb(title: "Best", value: viewModel.bestScore, metrics: metrics)
                    }

                    HStack(spacing: metrics.buttonGap) {
                        primaryButton(title: "New Run", systemImage: "sparkles") {
                            viewModel.startNewGame()
                            screen = .game
                        }

                        secondaryButton(title: "Continue", systemImage: "play.fill", isProminent: true) {
                            screen = .game
                        }
                        .opacity(viewModel.continueGameAvailable() ? 1 : 0.4)
                        .disabled(!viewModel.continueGameAvailable())
                    }
                }
                .padding(metrics.cardPadding)
                .premiumPanel(palette: palette, cornerRadius: 34)

                VStack(spacing: 18) {
                    BoardView(
                        board: viewModel.board,
                        palette: palette,
                        movePresentation: nil,
                        hintedDirection: nil
                    )
                    .frame(width: metrics.menuBoardSize, height: metrics.menuBoardSize)

                    progressPanel(
                        title: "Path To 2048",
                        subtitle: "Highest tile \(viewModel.highestTile)",
                        progress: progressToTarget(tile: viewModel.highestTile),
                        metrics: metrics
                    )
                }

                HStack(spacing: metrics.buttonGap) {
                    insightCard(title: "Wins", value: "\(viewModel.gamesWon)", note: "Total clears", metrics: metrics)
                    insightCard(title: "Win Rate", value: "\(Int(viewModel.winRate * 100))%", note: "Across all games", metrics: metrics)
                    insightCard(title: "Moves", value: "\(viewModel.stats.totalMoves)", note: "Lifetime inputs", metrics: metrics)
                }

                if !viewModel.unlockedAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        sectionLabel("Milestones")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.unlockedAchievements.suffix(4), id: \.id) { achievement in
                                    achievementCard(achievement: achievement, metrics: metrics)
                                }
                            }
                        }
                    }
                }

                VStack(spacing: metrics.buttonGap) {
                    helperPanel(
                        title: "Daily Edge",
                        description: viewModel.sessionSummarySubtitle,
                        icon: "bolt.fill",
                        metrics: metrics
                    )

                    HStack(spacing: metrics.buttonGap) {
                        secondaryButton(title: "Stats", systemImage: "chart.bar.fill") {
                            viewModel.showingStats = true
                        }
                        secondaryButton(title: "How To Play", systemImage: "questionmark.circle.fill") {
                            viewModel.showingHowToPlay = true
                        }
                        secondaryButton(title: "Settings", systemImage: "slider.horizontal.3") {
                            viewModel.showingSettings = true
                        }
                    }
                }
            }
            .padding(.horizontal, metrics.sidePadding)
            .padding(.top, metrics.topPadding)
            .padding(.bottom, metrics.bottomPadding)
        }
    }

    private func gameScreen(metrics: LayoutMetrics) -> some View {
        VStack(spacing: metrics.gameSectionGap) {
            VStack(spacing: metrics.headerPanelGap) {
                HStack(spacing: metrics.buttonGap) {
                    iconButton(systemImage: "house.fill", size: metrics.iconButtonSize) {
                        viewModel.abandonCurrentGame()
                        screen = .menu
                    }

                    VStack(alignment: .leading, spacing: metrics.gameHeaderTextSpacing) {
                        Text("Current Run")
                            .font(.system(size: metrics.gameEyebrowSize, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.accentSecondary.opacity(0.86))
                            .tracking(1.6)
                        Text(viewModel.sessionSummaryTitle)
                            .font(.system(size: metrics.gameTitleSize, weight: .black, design: .rounded))
                            .foregroundStyle(palette.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }

                    Spacer(minLength: 12)

                    iconButton(systemImage: "line.3.horizontal", size: metrics.iconButtonSize) {
                        showingGameMenu = true
                    }
                }
                .frame(height: metrics.headerHeight)

                HStack(spacing: metrics.buttonGap) {
                    scoreCard(title: "Score", value: viewModel.score, highlight: true, metrics: metrics)
                    scoreCard(title: "Best", value: viewModel.bestScore, highlight: false, metrics: metrics)
                }
            }
            .padding(metrics.headerPanelPadding)
            .background(
                RoundedRectangle(cornerRadius: metrics.headerPanelCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                palette.accent.opacity(0.08),
                                Color.white.opacity(0.06),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: metrics.headerPanelCornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    .shadow(color: palette.shadow.opacity(0.28), radius: 22, x: 0, y: 14)
            )
            .padding(.horizontal, metrics.headerSidePadding)
            .padding(.top, metrics.topPadding)

            BoardView(
                board: viewModel.board,
                palette: palette,
                movePresentation: viewModel.movePresentation,
                hintedDirection: viewModel.hintState?.direction
            )
            .frame(width: metrics.gameBoardSize, height: metrics.gameBoardSize)
            .frame(maxWidth: .infinity)
            .padding(.top, metrics.boardTopSpacing)
            .padding(.bottom, metrics.boardBottomSpacing)
            .padding(.horizontal, metrics.boardSidePadding)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 14)
                    .onEnded(handleDrag)
            )

            VStack(spacing: metrics.actionRowGap) {
                HStack(spacing: metrics.buttonGap) {
                    secondaryButton(title: "New Run", systemImage: "arrow.clockwise", isProminent: true, metrics: metrics) {
                        viewModel.startNewGame()
                    }
                    .frame(height: metrics.primaryActionHeight)

                    tertiaryButton(title: "Hint", systemImage: "scope", isDisabled: false, isProminent: true, metrics: metrics) {
                        viewModel.requestHint()
                    }
                    .frame(width: metrics.featureActionWidth, height: metrics.primaryActionHeight)
                }

                HStack(spacing: metrics.buttonGap) {
                    tertiaryButton(title: "Undo", systemImage: "arrow.uturn.backward", isDisabled: !viewModel.canUndo, metrics: metrics) {
                        viewModel.undoLastMove()
                    }
                    .frame(height: metrics.utilityActionHeight)

                    tertiaryButton(title: "Stats", systemImage: "chart.bar", isDisabled: false, metrics: metrics) {
                        viewModel.showingStats = true
                    }
                    .frame(height: metrics.utilityActionHeight)

                    tertiaryButton(title: "Settings", systemImage: "gearshape.fill", isDisabled: false, metrics: metrics) {
                        viewModel.showingSettings = true
                    }
                    .frame(height: metrics.utilityActionHeight)
                }
            }
            .padding(metrics.actionDockPadding)
            .background(
                RoundedRectangle(cornerRadius: metrics.actionDockCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.105),
                                palette.accent.opacity(0.052),
                                Color.black.opacity(0.075),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: metrics.actionDockCornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: palette.shadow.opacity(0.26), radius: 18, x: 0, y: 12)
            )
            .padding(.horizontal, metrics.actionSidePadding)
            .padding(.bottom, metrics.bottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func scoreOrb(title: String, value: Int, metrics: LayoutMetrics) -> some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(palette.textSecondary)
                .tracking(1.8)
            Text("\(value)")
                .font(.system(size: metrics.orbValueSize, weight: .black, design: .rounded))
                .foregroundStyle(palette.textPrimary)
                .minimumScaleFactor(0.6)
        }
        .frame(width: metrics.orbSize, height: metrics.orbSize)
        .background(
            Circle()
                .fill(palette.panelGradient)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
        .shadow(color: palette.shadow.opacity(0.6), radius: 18, x: 0, y: 10)
    }

    private func scoreCard(title: String, value: Int, highlight: Bool, metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.scoreCardSpacing) {
            HStack(spacing: 6) {
                Circle()
                    .fill(highlight ? palette.accent : palette.accentSecondary)
                    .frame(width: 6, height: 6)

                Text(title.uppercased())
                    .font(.system(size: metrics.scoreLabelSize, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.textSecondary)
                    .tracking(1.6)
            }

            Text("\(value)")
                .font(.system(size: metrics.scoreValueSize, weight: .black, design: .rounded))
                .foregroundStyle(palette.textPrimary)
                .minimumScaleFactor(0.55)

            progressBar(
                value: highlight ? progressToTarget(tile: viewModel.highestTile) : min(Double(viewModel.score) / Double(max(viewModel.bestScore, 1)), 1),
                tint: highlight ? palette.accent : palette.accentSecondary,
                height: metrics.scoreProgressHeight
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(metrics.scoreCardPadding)
        .frame(height: metrics.scoreCardHeight)
        .background(
            RoundedRectangle(cornerRadius: metrics.scoreCardCornerRadius, style: .continuous)
                .fill(Color.black.opacity(highlight ? 0.16 : 0.11))
                .overlay(
                    RoundedRectangle(cornerRadius: metrics.scoreCardCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(highlight ? 0.18 : 0.12), lineWidth: 1)
                )
        )
    }

    private func primaryButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.78))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(palette.heroGradient)
        )
        .shadow(color: palette.glow.opacity(0.26), radius: 20, x: 0, y: 10)
    }

    private func secondaryButton(
        title: String,
        systemImage: String,
        isProminent: Bool = false,
        metrics: LayoutMetrics? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let labelSize = metrics?.secondaryButtonLabelSize ?? 15
        let cornerRadius = metrics?.secondaryButtonCornerRadius ?? 24

        return Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: labelSize + 3, weight: .black))
                Text(title)
                    .font(.system(size: labelSize, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(isProminent ? Color.black.opacity(0.78) : palette.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 14)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(isProminent ? palette.heroGradient : palette.boardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(isProminent ? 0.22 : 0.10), lineWidth: 1)
                )
        )
        .shadow(color: isProminent ? palette.glow.opacity(0.22) : .clear, radius: 16, x: 0, y: 8)
    }

    private func tertiaryButton(
        title: String,
        systemImage: String,
        isDisabled: Bool,
        isProminent: Bool = false,
        metrics: LayoutMetrics? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let iconSize = metrics?.tertiaryButtonIconSize ?? 18
        let labelSize = metrics?.tertiaryButtonLabelSize ?? 13
        let cornerRadius = metrics?.tertiaryButtonCornerRadius ?? 22

        return Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .black))
                Text(title)
                    .font(.system(size: labelSize, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(palette.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    isProminent
                    ? LinearGradient(
                        colors: [
                            Color.white.opacity(0.20),
                            palette.accentSecondary.opacity(0.18),
                            Color.white.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white.opacity(0.115), Color.white.opacity(0.052)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(isProminent ? 0.20 : 0.10), lineWidth: 1)
                )
        )
        .opacity(isDisabled ? 0.35 : 1)
        .disabled(isDisabled)
    }

    private func iconButton(systemImage: String, size: CGFloat = 52, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.34, weight: .black))
                .foregroundStyle(palette.textPrimary)
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private func insightCard(title: String, value: String, note: String, metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(palette.textSecondary)
                .tracking(1.5)
            Text(value)
                .font(.system(size: metrics.insightValueSize, weight: .black, design: .rounded))
                .foregroundStyle(palette.textPrimary)
                .minimumScaleFactor(0.5)
            Text(note)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(metrics.smallCardPadding)
        .premiumPanel(palette: palette, cornerRadius: 24)
    }

    private func progressPanel(title: String, subtitle: String, progress: Double, metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(palette.textPrimary)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(palette.textSecondary)
            progressBar(value: progress, tint: palette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(metrics.cardPadding)
        .premiumPanel(palette: palette, cornerRadius: 28)
    }

    private func helperPanel(title: String, description: String, icon: String, metrics: LayoutMetrics) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(palette.accent)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.white.opacity(0.08)))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(metrics.cardPadding)
        .premiumPanel(palette: palette, cornerRadius: 28)
    }

    private func achievementCard(achievement: Achievement, metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(achievement.title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(palette.textPrimary)
            Text(achievement.detail)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: metrics.achievementCardWidth, alignment: .leading)
        .padding(metrics.smallCardPadding)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.boardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private func achievementToast(achievement: Achievement, metrics: LayoutMetrics) -> some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(palette.heroGradient))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Achievement Unlocked")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textSecondary)
                    Text(achievement.title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .premiumPanel(palette: palette, cornerRadius: 26)
            .padding(.horizontal, metrics.sidePadding)
            .padding(.top, metrics.topPadding + 8)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func overlayView(for overlay: GameViewModel.OverlayState, metrics: LayoutMetrics) -> some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text(overlay == .victory ? "You Made 2048" : "Run Complete")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(palette.textPrimary)

                Text(
                    overlay == .victory
                    ? "Bank the win, keep climbing, or spin up a fresh board while you’re hot."
                    : "You’re out of space. Reset instantly or head back to the menu and review your stats."
                )
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: metrics.buttonGap) {
                    secondaryButton(title: "Menu", systemImage: "house.fill") {
                        viewModel.dismissOverlay()
                        viewModel.abandonCurrentGame()
                        screen = .menu
                    }

                    if overlay == .victory {
                        secondaryButton(title: "Keep Going", systemImage: "arrow.right") {
                            viewModel.continueAfterVictory()
                        }
                    }

                    primaryButton(title: "New Run", systemImage: "arrow.clockwise") {
                        viewModel.startNewGame()
                    }
                }
            }
            .padding(metrics.cardPadding)
            .frame(maxWidth: 540)
            .premiumPanel(palette: palette, cornerRadius: 34)
            .padding(.horizontal, metrics.sidePadding)
        }
    }

    private var gameMenuSheet: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: viewModel.hintState == nil ? "waveform.path.ecg" : "sparkles")
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(palette.accent)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(Color.white.opacity(0.08)))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(gameMenuTitle)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(palette.textPrimary)
                                Text(gameMenuDescription)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(palette.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 12) {
                            gameMenuStatCard(title: "Highest", value: "\(viewModel.highestTile)", note: "Tile reached")
                            gameMenuStatCard(title: "Streak", value: "\(viewModel.stats.currentWinStreak)", note: "Current wins")
                            gameMenuStatCard(title: "Hints", value: "\(viewModel.stats.totalHints)", note: "Used overall")
                        }
                    }
                    .padding(20)
                    .premiumPanel(palette: palette, cornerRadius: 28)

                    Button {
                        showingGameMenu = false
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(150))
                            viewModel.showingHowToPlay = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 18, weight: .black))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("How To Play")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                Text("Open the gameplay guide and strategy tips.")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(palette.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(palette.textPrimary)
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .premiumPanel(palette: palette, cornerRadius: 24)
                }
                .padding(20)
            }
            .navigationTitle("Run Menu")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var gameMenuTitle: String {
        if let hintState = viewModel.hintState {
            return "Suggested Move: \(hintState.direction.label)"
        }
        return "Board Rhythm"
    }

    private var gameMenuDescription: String {
        if let hintState = viewModel.hintState {
            return "Projected +\(hintState.predictedScoreGain) score with \(hintState.emptyCellCount) empty cells after the move."
        }
        return viewModel.sessionSummarySubtitle
    }

    private func gameMenuStatCard(title: String, value: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(palette.textSecondary)
                .tracking(1.5)
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(palette.textPrimary)
                .minimumScaleFactor(0.6)
            Text(note)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(palette.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.boardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("Feel") {
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
                    Toggle("Reduced Motion", isOn: Binding(
                        get: { viewModel.settings.reducedMotionEnabled },
                        set: {
                            viewModel.settings.reducedMotionEnabled = $0
                            viewModel.saveSettings()
                        }
                    ))
                }

                Section("Theme") {
                    Picker("Visual Theme", selection: Binding(
                        get: { viewModel.settings.selectedTheme },
                        set: {
                            viewModel.settings.selectedTheme = $0
                            viewModel.saveSettings()
                        }
                    )) {
                        ForEach(VisualTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.inline)
                }
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
                statRow(title: "Games Won", value: "\(viewModel.stats.gamesWon)")
                statRow(title: "Best Win Streak", value: "\(viewModel.stats.bestWinStreak)")
                statRow(title: "Total Moves", value: "\(viewModel.stats.totalMoves)")
                statRow(title: "Undo Uses", value: "\(viewModel.stats.totalUndos)")
                statRow(title: "Hint Uses", value: "\(viewModel.stats.totalHints)")
                statRow(title: "Last Finished Score", value: "\(viewModel.stats.lastFinishedScore)")
                statRow(title: "Last Finished Tile", value: "\(viewModel.stats.lastFinishedHighestTile)")
            }
            .navigationTitle("Stats")
        }
    }

    private var howToPlaySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("How To Play")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.primary)

                    howToPlaySection(
                        title: "Core Rules",
                        lines: [
                            "Swipe in any direction to slide every tile.",
                            "Matching values merge once per move.",
                            "Every valid move spawns one new tile.",
                            "Reach 2048 to win, then keep pushing if you want a monster run.",
                        ]
                    )

                    howToPlaySection(
                        title: "Premium Tools",
                        lines: [
                            "Undo restores the previous board once.",
                            "Hint previews the strongest next direction without changing the board.",
                            "Reduced Motion keeps the board readable if you want calmer animation.",
                        ]
                    )

                    howToPlaySection(
                        title: "Strategy",
                        lines: [
                            "Keep your biggest tile anchored in one corner.",
                            "Avoid breaking your gradient of descending values.",
                            "Protect at least one open lane so new spawns don’t trap you.",
                        ]
                    )

                    Button("Start Playing") {
                        viewModel.markOnboardingSeen()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 10)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func howToPlaySection(title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            ForEach(lines, id: \.self) { line in
                Text("• \(line)")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
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

    private func progressBar(value: Double, tint: Color, height: CGFloat = 10) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                Capsule()
                    .fill(tint)
                    .frame(width: max(12, proxy.size.width * value))
            }
        }
        .frame(height: height)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(palette.textSecondary)
            .tracking(2)
            .frame(maxWidth: .infinity, alignment: .leading)
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

    private func progressToTarget(tile: Int) -> Double {
        guard tile > 0 else { return 0.03 }
        let raw = log2(Double(tile)) / log2(Double(winningTileValue))
        return min(max(raw, 0.03), 1)
    }
}

private struct LayoutMetrics {
    let proxy: GeometryProxy

    var width: CGFloat { proxy.size.width }
    var height: CGFloat { proxy.size.height }
    var safeWidth: CGFloat { width - proxy.safeAreaInsets.leading - proxy.safeAreaInsets.trailing }
    var safeHeight: CGFloat { height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom }

    private var isShortPhone: Bool { safeHeight < 760 }
    private var isNarrow: Bool { safeWidth < 380 }
    private var isTabletLike: Bool { safeWidth >= 700 }
    private var widthScale: CGFloat { clamp(safeWidth / 390, min: 0.90, max: 1.18) }
    private var heightScale: CGFloat { clamp(safeHeight / 844, min: 0.82, max: 1.18) }
    private var compactScale: CGFloat { clamp((widthScale * 0.62) + (heightScale * 0.38), min: 0.88, max: 1.16) }

    var topPadding: CGFloat { proxy.safeAreaInsets.top + clamp(safeHeight * 0.006, min: 2, max: 8) }
    var bottomPadding: CGFloat { proxy.safeAreaInsets.bottom + clamp(safeHeight * 0.010, min: 8, max: 14) }
    var sidePadding: CGFloat { isTabletLike ? 36 : (isNarrow ? 16 : 22) }
    var sectionGap: CGFloat { isShortPhone ? 10 : 14 }
    var buttonGap: CGFloat { clamp(safeWidth * 0.028, min: 10, max: 14) }
    var cardPadding: CGFloat { isShortPhone ? 16 : 22 }
    var smallCardPadding: CGFloat { isShortPhone ? 14 : 16 }
    var heroTitleSize: CGFloat { isTabletLike ? 72 : (isNarrow ? 46 : 58) }
    var bodySize: CGFloat { isShortPhone ? 14 : 16 }
    var orbSize: CGFloat { isTabletLike ? 118 : 96 }
    var orbValueSize: CGFloat { isTabletLike ? 34 : 28 }
    var headerSidePadding: CGFloat { isTabletLike ? 40 : clamp(safeWidth * 0.042, min: 12, max: 18) }
    var boardSidePadding: CGFloat { isTabletLike ? 24 : 0 }
    var actionSidePadding: CGFloat { isTabletLike ? 40 : clamp(safeWidth * 0.038, min: 10, max: 15) }
    var gameSectionGap: CGFloat { clamp(safeHeight * 0.014, min: 10, max: 14) }
    var headerPanelGap: CGFloat { clamp(safeHeight * 0.010, min: 8, max: 12) }
    var headerPanelPadding: CGFloat { clamp(12 * compactScale, min: 10, max: 14) }
    var headerPanelCornerRadius: CGFloat { clamp(28 * compactScale, min: 24, max: 32) }
    var gameHeaderTextSpacing: CGFloat { clamp(2.4 * compactScale, min: 1.5, max: 3) }
    var gameHeaderBottomSpacing: CGFloat { clamp(safeHeight * 0.004, min: 2, max: 6) }
    var boardTopSpacing: CGFloat { clamp(safeHeight * 0.004, min: 2, max: 5) }
    var boardBottomSpacing: CGFloat { clamp(safeHeight * 0.010, min: 8, max: 12) }
    var actionRowGap: CGFloat { clamp(safeHeight * 0.009, min: 7, max: 10) }
    var gameEyebrowSize: CGFloat { clamp(safeWidth * 0.030, min: 10.5, max: 13) }
    var gameTitleSize: CGFloat { clamp(safeWidth * 0.059, min: 19, max: 24) }
    var iconButtonSize: CGFloat { clamp(min(safeWidth, safeHeight) * 0.102, min: 40, max: 46) }
    var headerHeight: CGFloat { max(iconButtonSize, gameTitleSize * 1.22) }
    var scoreLabelSize: CGFloat { clamp(11 * compactScale, min: 10.5, max: 12.5) }
    var scoreValueSize: CGFloat { isTabletLike ? 38 : clamp(safeWidth * 0.064, min: 22, max: 26) }
    var scoreCardPadding: CGFloat { clamp(11.5 * compactScale, min: 9, max: 12) }
    var scoreCardSpacing: CGFloat { clamp(4.5 * compactScale, min: 3, max: 5.5) }
    var scoreProgressHeight: CGFloat { clamp(7 * compactScale, min: 6, max: 8) }
    var scoreCardCornerRadius: CGFloat { clamp(24 * compactScale, min: 22, max: 26) }
    var insightValueSize: CGFloat { isTabletLike ? 30 : 24 }
    var achievementCardWidth: CGFloat { isTabletLike ? 240 : 200 }
    var scoreCardHeight: CGFloat { clamp(safeHeight * 0.086, min: 68, max: 78) }
    var tertiaryButtonHeight: CGFloat { utilityActionHeight }
    var tertiaryButtonVerticalPadding: CGFloat { clamp(6.2 * compactScale, min: 5, max: 7) }
    var tertiaryButtonIconSize: CGFloat { clamp(13.8 * compactScale, min: 13, max: 15.5) }
    var tertiaryButtonLabelSize: CGFloat { clamp(10.8 * compactScale, min: 10.2, max: 12) }
    var tertiaryButtonCornerRadius: CGFloat { clamp(16 * compactScale, min: 15, max: 18) }
    var secondaryButtonHeight: CGFloat { primaryActionHeight }
    var secondaryButtonVerticalPadding: CGFloat { clamp(8.2 * compactScale, min: 7, max: 9.5) }
    var secondaryButtonLabelSize: CGFloat { clamp(14 * compactScale, min: 13, max: 15.5) }
    var secondaryButtonCornerRadius: CGFloat { clamp(18 * compactScale, min: 16, max: 20) }
    var primaryActionHeight: CGFloat { clamp(safeHeight * 0.050, min: 42, max: 50) }
    var utilityActionHeight: CGFloat { clamp(safeHeight * 0.052, min: 42, max: 48) }
    var featureActionWidth: CGFloat {
        clamp(safeWidth * 0.245, min: 94, max: isTabletLike ? 150 : 112)
    }
    var actionDockPadding: CGFloat { clamp(7.5 * compactScale, min: 6, max: 9) }
    var actionDockCornerRadius: CGFloat { clamp(22 * compactScale, min: 20, max: 24) }
    var actionBlockHeight: CGFloat { primaryActionHeight + utilityActionHeight + actionRowGap + (actionDockPadding * 2) }
    var headerPanelHeight: CGFloat { headerHeight + scoreCardHeight + headerPanelGap + (headerPanelPadding * 2) }

    var menuBoardSize: CGFloat {
        min(safeWidth - (sidePadding * 2), isTabletLike ? 430 : 350)
    }

    var gameBoardSize: CGFloat {
        let cap: CGFloat = isTabletLike ? 660 : 600
        let widthLimited = min(safeWidth - (boardSidePadding * 2), cap)
        let heightBudget = safeHeight
            - topPadding
            - headerPanelHeight
            - gameSectionGap
            - boardTopSpacing
            - boardBottomSpacing
            - actionBlockHeight
            - bottomPadding
        return max(0, min(widthLimited, heightBudget))
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}

private extension View {
    func premiumPanel(palette: PremiumPalette, cornerRadius: CGFloat) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(palette.panelGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(palette.panelStroke, lineWidth: 1)
                )
        )
    }
}

#Preview {
    ContentView()
}

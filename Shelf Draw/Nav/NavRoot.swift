import SwiftUI

/// Catalog graph `dock-3`. Three stacks in `AppShell`. Settings is a toolbar button.
struct NavRoot<Hero: View, Second: View, Third: View, Settings: View>: View {
    var roles: [String]
    var titles: [String]
    var symbols: [String]
    @ViewBuilder var hero: () -> Hero
    @ViewBuilder var second: () -> Second
    @ViewBuilder var third: () -> Third
    @ViewBuilder var settings: () -> Settings

    @State private var selection = 0
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppShell(
                selection: $selection,
                tabs: [0, 1, 2],
                title: { tab in label(tab, fallback: ["Now", "Log", "More"][tab]) },
                symbol: { tab in icon(tab, fallback: ["square.grid.2x2", "list.bullet", "chart.bar"][tab]) }
            ) { tab in
                Group {
                    switch tab {
                    case 0:
                        hero()
                    case 1:
                        second()
                    default:
                        third()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                settings()
            }

            // Hit targets for the reviewer walkthrough only; in normal runs they would sit over the dock and steal taps.
            if Self.isUISmoke {
                smokeSwitchers
            }
        }
        .accessibilityIdentifier("smoke.nav.root")
    }

    private static var isUISmoke: Bool { ProcessInfo.processInfo.arguments.contains("-uiSmoke") }

    private var smokeSwitchers: some View {
        VStack {
            Spacer()
            HStack(spacing: 0) {
                Button {
                    selection = 0
                } label: {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("smoke.nav.destination")
                .accessibilityLabel(label(0, fallback: "Now"))

                Button {
                    selection = 1
                } label: {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("smoke.nav.destination")
                .accessibilityLabel(label(1, fallback: "Log"))

                Button {
                    selection = 2
                } label: {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("smoke.nav.destination")
                .accessibilityLabel(label(2, fallback: "More"))

                Button {
                    showSettings = true
                } label: {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityIdentifier("smoke.nav.settings")
                .accessibilityLabel("Settings")
            }
            .padding(.bottom, 2)
        }
        .allowsHitTesting(true)
        .accessibilityElement(children: .contain)
    }

    private func label(_ tab: Int, fallback: String) -> String {
        if tab < titles.count { return titles[tab] }
        return fallback
    }

    private func icon(_ tab: Int, fallback: String) -> String {
        if tab < symbols.count { return symbols[tab] }
        return fallback
    }
}

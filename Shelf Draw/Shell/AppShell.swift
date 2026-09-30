import SwiftUI

/// A real `TabView` with `.tabItem` and one stack inside each tab.
/// iPhone shows the bottom bar; iPad shows the same tabs as a top bar, so state survives size changes.
struct AppShell<Tab: Hashable, Content: View>: View {
    @Binding var selection: Tab
    var tabs: [Tab]
    var title: (Tab) -> String
    var symbol: (Tab) -> String
    @ViewBuilder var content: (Tab) -> Content

    var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs, id: \.self) { tab in
                NavigationStack {
                    content(tab)
                }
                .tabItem { Label(title(tab), systemImage: symbol(tab)) }
                .tag(tab)
            }
        }
    }
}

/// The stack is an array. A sheet is an optional route on the store, not a pile of links.
struct StackScreen<Route: Hashable, Root: View, Destination: View>: View {
    @Binding var path: [Route]
    @ViewBuilder var root: () -> Root
    @ViewBuilder var destination: (Route) -> Destination

    var body: some View {
        NavigationStack(path: $path) {
            root()
                .navigationDestination(for: Route.self, destination: destination)
        }
    }
}

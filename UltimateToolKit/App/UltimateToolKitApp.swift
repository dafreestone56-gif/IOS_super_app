import SwiftUI

@main
@MainActor
struct UltimateToolKitApp: App {
    @StateObject private var services = ToolkitServices()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(services)
        }
    }
}

enum MainTab: String, CaseIterable, Identifiable {
    case home
    case automation
    case widgets
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .automation: return "Automation"
        case .widgets: return "Widgets"
        case .more: return "More"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .automation: return "gearshape.2"
        case .widgets: return "square.grid.2x2"
        case .more: return "ellipsis"
        }
    }
}

struct RootView: View {
    @State private var selection: MainTab = .home

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                HomeView()
                    .navigationDestination(for: ToolkitModule.self) { module in
                        ModuleDestinationView(module: module)
                    }
            }
            .tabItem { Label(MainTab.home.title, systemImage: MainTab.home.symbol) }
            .tag(MainTab.home)

            NavigationStack { AutomationView() }
                .tabItem { Label(MainTab.automation.title, systemImage: MainTab.automation.symbol) }
                .tag(MainTab.automation)

            NavigationStack { WidgetStudioView() }
                .tabItem { Label(MainTab.widgets.title, systemImage: MainTab.widgets.symbol) }
                .tag(MainTab.widgets)

            NavigationStack {
                MoreView()
                    .navigationDestination(for: ToolkitModule.self) { module in
                        ModuleDestinationView(module: module)
                    }
            }
            .tabItem { Label(MainTab.more.title, systemImage: MainTab.more.symbol) }
            .tag(MainTab.more)
        }
        .tint(.blue)
    }
}

struct ModuleDestinationView: View {
    let module: ToolkitModule

    var body: some View {
        switch module {
        case .bluetooth:
            BluetoothView()
        case .sensors:
            SensorsView()
        case .wifi, .network:
            NetworkView()
        case .nfc:
            NFCView()
        case .automation:
            AutomationView()
        case .widgetStudio:
            WidgetStudioView()
        case .developerTools:
            DeveloperToolsView()
        case .shortcuts:
            ShortcutsView()
        case .settings:
            SettingsView()
        case .camera:
            CameraView()
        case .audio:
            AudioView()
        case .haptics:
            HapticsView()
        case .ai:
            AIView()
        }
    }
}

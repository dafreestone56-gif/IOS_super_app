import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var searchText = ""

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var filteredTools: [ToolkitModule] {
        guard !searchText.isEmpty else { return ToolkitModule.toolList }
        return ToolkitModule.allCases.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
                || $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Playground")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Your all-in-one developer toolkit.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                searchField

                HStack {
                    SectionLabel(title: "Favorites")
                    Spacer()
                    Button("Edit") { services.log("Favorites editor requested") }
                        .font(.caption)
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(ToolkitModule.favorites) { module in
                        NavigationLink(value: module) {
                            ModuleCard(module: module)
                        }
                        .buttonStyle(.plain)
                    }
                }

                SectionLabel(title: "Tools")
                GlassPanel {
                    VStack(spacing: 0) {
                        ForEach(filteredTools) { module in
                            NavigationLink(value: module) {
                                ToolRow(module: module)
                            }
                            .buttonStyle(.plain)
                            Divider().background(AppTheme.hairline)
                        }
                    }
                }

                SectionLabel(title: "Recent Events")
                GlassPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        if services.logs.isEmpty {
                            Text("Toolkit booted. Events from scans, automations, and tools will appear here.")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        } else {
                            ForEach(services.logs.prefix(4)) { log in
                                HStack {
                                    Text(log.level.rawValue)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(log.level == .error ? .red : .blue)
                                    Text(log.message)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    services.log("Settings shortcut opened")
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .toolkitScreen()
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)
            TextField("Search modules", text: $searchText)
                .textInputAutocapitalization(.never)
                .foregroundStyle(AppTheme.primaryText)
        }
        .padding(11)
        .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

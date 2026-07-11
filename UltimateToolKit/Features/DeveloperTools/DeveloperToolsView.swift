import SwiftUI
import UIKit

struct DeveloperToolsView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var selectedTool: DeveloperToolKind = .formatJSON
    @State private var input = ""
    @State private var auxiliaryInput = ""
    @State private var output = ""
    @State private var history: [ToolHistoryItem] = AppPersistence.load([ToolHistoryItem].self, key: "tools.history", fallback: [])

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Tool", selection: $selectedTool) {
                    ForEach(DeveloperToolKind.allCases) { tool in
                        Text(tool.rawValue).tag(tool)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)

                if selectedTool.needsAuxiliaryInput {
                    TextField(selectedTool.auxiliaryPlaceholder, text: $auxiliaryInput)
                        .textInputAutocapitalization(.never)
                        .padding(10)
                        .background(AppTheme.elevatedPanel, in: RoundedRectangle(cornerRadius: 8))
                }

                TextEditor(text: $input)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(AppTheme.primaryText)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))

                HStack {
                    Button {
                        output = services.utilities.run(selectedTool, input: input, pattern: auxiliaryInput)
                        saveHistory()
                        services.log("\(selectedTool.rawValue) ran")
                    } label: {
                        Label("Run", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        input = ""
                        auxiliaryInput = ""
                        output = ""
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)

                    if !output.isEmpty {
                        Button {
                            UIPasteboard.general.string = output
                            services.log("Developer tool output copied")
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                SectionLabel(title: "Output")
                outputPanel

                if !history.isEmpty {
                    SectionLabel(title: "History")
                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(history.prefix(8)) { item in
                                Button {
                                    input = item.inputPreview
                                    output = item.outputPreview
                                    selectedTool = DeveloperToolKind.allCases.first(where: { $0.rawValue == item.toolName }) ?? selectedTool
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(item.toolName)
                                                .font(.caption.weight(.semibold))
                                            Spacer()
                                            Text(item.date, style: .time)
                                                .font(.caption2)
                                                .foregroundStyle(AppTheme.tertiaryText)
                                        }
                                        Text(item.outputPreview)
                                            .font(.caption2)
                                            .foregroundStyle(AppTheme.secondaryText)
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                Divider().background(AppTheme.hairline)
                            }
                            Button("Clear Tool History") {
                                history = []
                                AppPersistence.save(history, key: "tools.history")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Developer Tools")
        .toolkitScreen()
    }

    private var outputPanel: some View {
        Group {
            if output.isEmpty {
                Text("Run \(selectedTool.rawValue) to generate local output.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8))
            } else {
                Text(output)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(AppTheme.primaryText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func saveHistory() {
        let item = ToolHistoryItem(
            date: Date(),
            toolName: selectedTool.rawValue,
            inputPreview: String(input.prefix(500)),
            outputPreview: String(output.prefix(800))
        )
        history.insert(item, at: 0)
        history = Array(history.prefix(30))
        AppPersistence.save(history, key: "tools.history")
    }
}

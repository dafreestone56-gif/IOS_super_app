import SwiftUI

struct DeveloperToolsView: View {
    @EnvironmentObject private var services: ToolkitServices
    @State private var selectedTool: DeveloperToolKind = .formatJSON
    @State private var input = ""
    @State private var pattern = ""
    @State private var output = "Choose a tool, enter input, and run it."

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

                if selectedTool == .regex {
                    TextField("Regex pattern", text: $pattern)
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
                        output = services.utilities.run(selectedTool, input: input, pattern: pattern)
                        services.log("\(selectedTool.rawValue) ran")
                    } label: {
                        Label("Run", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        input = ""
                        output = ""
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                }

                SectionLabel(title: "Output")
                Text(output)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(AppTheme.primaryText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(16)
        }
        .navigationTitle("Developer Tools")
        .toolkitScreen()
    }
}

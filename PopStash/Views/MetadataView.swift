import SwiftUI

struct MetadataView: View {
    let item: ClipboardItem
    let manager: ClipboardManager
    
    @State private var selectedTab: Tab = .preview
    
    enum Tab: String, CaseIterable, Identifiable {
        case preview = "Preview"
        case details = "Details"
        case actions = "Actions"
        
        var id: String { self.rawValue }
        
        var systemImage: String {
            switch self {
            case .preview: "eye"
            case .details: "info.circle"
            case .actions: "hammer"
            }
        }
    }
    
    var body: some View {
        // FIX: Apply the glass effect to the entire view for cohesion.
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    ForEach(Tab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.systemImage).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Materials.ultraThin)
            
            Divider()

            Group {
                switch selectedTab {
                case .preview:
                    PreviewTabView(item: item)
                case .details:
                    DetailsTabView(item: item)
                case .actions:
                    ActionsTabView(item: item, manager: manager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .glassEffect()
    }
}

// ... (Rest of the MetadataView subviews remain the same)

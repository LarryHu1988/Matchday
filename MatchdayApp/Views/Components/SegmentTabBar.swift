import SwiftUI

// MARK: - Segment Tab Bar
// Uses the native iOS segmented Picker style, matching the scorer/assists
// picker in CompPlayersContent. Wrapped with extra vertical padding for a
// slightly taller feel. Full-width, transparent background.

struct SegmentTabBar<Tab: Hashable>: View {
    let tabs: [(tab: Tab, title: String)]
    @Binding var selected: Tab

    var body: some View {
        Picker(selection: $selected) {
            ForEach(tabs, id: \.tab) { item in
                Text(item.title).tag(item.tab)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

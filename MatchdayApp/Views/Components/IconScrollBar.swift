import SwiftUI

// MARK: - Horizontal Icon Scroll Bar
// Displays a row of circular crest icons for teams or competitions.
// Icons are horizontally tiled with a glass-morphism background.
// Set showAllButton to false to hide the "All" option (e.g. Teams tab).

struct IconScrollBar: View {
    let items: [IconItem]
    @Binding var selectedId: Int? // nil = "All" or first item
    var showAllButton: Bool = true

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                if showAllButton {
                    IconCircle(
                        imageURL: nil,
                        label: L10n.allTeams,
                        isSelected: selectedId == nil,
                        systemIcon: "square.grid.2x2"
                    )
                    .onTapGesture { selectedId = nil }
                }

                ForEach(items) { item in
                    IconCircle(
                        imageURL: item.imageURL,
                        label: item.displayLabel,
                        isSelected: selectedId == item.id
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if showAllButton {
                                selectedId = selectedId == item.id ? nil : item.id
                            } else {
                                selectedId = item.id
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Icon Item Model

struct IconItem: Identifiable {
    let id: Int
    let name: String
    let shortName: String
    let imageURL: String?

    /// Smart label: use shortName if name is too long (> 8 chars)
    var displayLabel: String {
        if name.count > 8 && !shortName.isEmpty {
            return shortName
        }
        return name
    }
}

// MARK: - Single Circular Icon

struct IconCircle: View {
    let imageURL: String?
    let label: String
    let isSelected: Bool
    var systemIcon: String? = nil

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Glass circle background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)

                // Selection ring
                if isSelected {
                    Circle()
                        .strokeBorder(Color.green, lineWidth: 2.5)
                        .frame(width: 60, height: 60)
                }

                if let systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? .green : .secondary)
                } else {
                    CrestImage(imageURL, size: 38)
                }
            }

            Text(label)
                .font(.caption2)
                .fontWeight(isSelected ? .medium : .regular)
                .foregroundStyle(isSelected ? .green : .secondary)
                .lineLimit(1)
                .frame(width: 64)
        }
    }
}

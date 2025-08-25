//
//  ToolbarSelectorButton.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import SwiftUI

struct ToolbarSelectorButton: View {
    let item: ToolbarItem
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                Text(item.title)
                    .font(.system(size: 12))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .foregroundColor(isSelected ? Color.accentColor : Color.secondary)
            .background(
                Group {
                    if isSelected {
                        Color.accentColor.opacity(0.1)
                    } else if isHovering {
                        Color.secondary.opacity(0.1)
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

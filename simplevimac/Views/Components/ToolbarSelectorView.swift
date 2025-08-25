//
//  ToolbarSelectorView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import AppKit

struct ToolbarSelectorView: View {
    @Binding var selectedIndex: Int
    let items: [ToolbarItem] = [
        .init(icon: "gearshape.fill", title: "通用"),
        .init(icon: "command", title: "快捷键"),
        .init(icon: "info.bubble", title: "关于")
    ]

    var body: some View {
        HStack(spacing: 24) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                // Each button gets its own hover state
                ToolbarSelectorButton(
                    item: item,
                    isSelected: selectedIndex == index,
                    action: { selectedIndex = index }
                )
            }
        }
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

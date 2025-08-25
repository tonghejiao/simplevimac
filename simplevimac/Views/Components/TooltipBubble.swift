//
//  TooltipBubble.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import AppKit

struct TooltipBubble: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.primary)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(radius: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.25))
            )
            .fixedSize()
    }
}

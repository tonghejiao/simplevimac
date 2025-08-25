//
//  WindowLevelGroupView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import SwiftUI

struct WindowLevelGroupView: View {
    @ObservedObject var group: Config.WindowLevelGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("匹配类型", selection: $group.mode) {
                ForEach(Config.WindowLevelGroup.ModeType.allCases, id: \.self) { mode in
                    Text(DisplayTextMapper.label(mode)).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            if group.mode == .title {
                WindowLevelConfigListView(configs: $group.title)
            } else {
                WindowLevelConfigListView(configs: $group.url)
            }
        }
    }
}

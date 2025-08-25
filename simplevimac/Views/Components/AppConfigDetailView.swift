//
//  AppConfigDetailView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import SwiftUI

struct AppConfigDetailView: View {
    @ObservedObject var appConfig: Config.AppLevelConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("默认配置")
                .font(.headline)

            Picker("模式", selection: $appConfig.mode) {
                ForEach(Config.ModeType.allCases, id: \.self) { mode in
                    Text(DisplayTextMapper.label(mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            
            DefaultKeyBindingsView(bindings: $appConfig.iDefault)

            Text("窗口级规则")
                .font(.headline)

            WindowLevelGroupView(group: appConfig.window)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("应用级规则配置详情")
    }
}

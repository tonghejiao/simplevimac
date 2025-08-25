//
//  DefaultKeyBindingsView.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/8/13.
//

import SwiftUICore
import SwiftUI

struct DefaultKeyBindingsView: View {
    @Binding var bindings: [KeyMapper.KeyBinding]
    @State private var selectedIndices: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            List {
                ForEach($bindings) { $binding in
                    HStack(spacing: 12) {
                        Toggle(isOn: Binding(
                            get: { selectedIndices.contains(binding.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedIndices.insert(binding.id)
                                } else {
                                    selectedIndices.remove(binding.id)
                                }
                            })
                        ) {
                            EmptyView()
                        }
                        .labelsHidden()
                        .frame(width: 20)
                        
                        Toggle(isOn: $binding.iSwitch) { EmptyView() }
                            .toggleStyle(.switch)
                            .labelsHidden()
                        
                        KeySpecEditor(spec: $binding.trigger, showMouseAndCommand: false)
                        Text("→")
                            .frame(width: 40)
                        KeySpecEditor(spec: $binding.action, showMouseAndCommand: true)
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .frame(height: 300)
            
            HStack(spacing: 12) {
                Button("全选") {
                    let allIds = Set(bindings.map(\.id))
                    if selectedIndices == allIds {
                        selectedIndices.removeAll() // 当前已全选，再点一下取消全选
                    } else {
                        selectedIndices = allIds   // 否则执行全选
                    }
                }
                
                Button("新增") {
                    bindings.append(KeyMapper.KeyBinding(iSwitch: true, trigger: .init(), action: .init()))
                }
                
                Button("删除") {
                    bindings.removeAll { selectedIndices.contains($0.id) }
                    selectedIndices.removeAll()
                }
                .disabled(selectedIndices.isEmpty)
            }
            .padding(.leading, 12)
        }
    }
}

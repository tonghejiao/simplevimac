//
//  Constant.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/7/12.
//

import CoreGraphics

public struct Role {
    static let webArea = "AXWebArea"
    static let tabGroup = "AXTabGroup"
    static let toolbar = "AXToolbar"
    static let table = "AXTable"
    static let outline = "AXOutline"
    
    static let textField = "AXTextField"
    static let textArea = "AXTextArea"
    static let searchField = "AXSearchField"
    static let editableText = "AXEditableText"
    static let comboBox = "AXComboBox"
}

public struct Constant {
    static let allowModifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
    
    static let editableElementRoles: Set<String> = [Role.textField, Role.textArea, Role.searchField, Role.editableText, Role.comboBox]

    static let cornerRadius: CGFloat = 4
    
    static let fontSize: CGFloat = 10
}

enum Mode {
    case normal
    case hints
}

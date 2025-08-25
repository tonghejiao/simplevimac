//
//  WebAreaURLResolver.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/7/11.
//

import Cocoa
import ApplicationServices

class WebAreaURLResolver {
    
    static func getURL(of window: AXUIElement) -> String? {
        return findURLInDescendants(of: window, maxDepth: 10)
    }

    private static func getChildren(of element: AXUIElement, role: String?) -> [AXUIElement]? {
        var childrenObj: AnyObject?

        if role == Role.table || role == Role.outline {
            if AXUIElementCopyAttributeValue(element, kAXVisibleRowsAttribute as CFString, &childrenObj) == .success,
               let visibleRows = childrenObj as? [AXUIElement] {
                return visibleRows
            } else {
                return nil
            }
        } else {
            if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenObj) == .success,
               let children = childrenObj as? [AXUIElement] {
                return children
            } else {
                return nil
            }
        }
    }

    private static func findURLInDescendants(of element: AXUIElement, maxDepth: Int, depth: Int = 0) -> String? {
        guard depth <= maxDepth else { return nil }
        
        var role: String? = nil
        var roleObj: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleObj) == .success {
            role = roleObj as? String
            if role == Role.webArea {
                let url = getAXDocument(of: element)
                return url
            } else if role == Role.tabGroup || role == Role.toolbar {
                return nil
            }
        }

        guard let children = getChildren(of: element, role: role) else {
            return nil
        }

        for child in children {
            if let url = findURLInDescendants(of: child, maxDepth: maxDepth, depth: depth + 1) {
                return url
            }
        }

        return nil
    }

    private static func getAXDocument(of element: AXUIElement) -> String? {
        var doc: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXURLAttribute as CFString, &doc) == .success,
            let cfurl = doc {
                return cfurl.absoluteString
        }
        return nil
    }
}

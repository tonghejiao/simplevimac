//
//  SmoothScroller.swift
//  simplevimac
//
//  Created by 童菏蛟 on 2025/6/29.
//

import Cocoa
import ApplicationServices
import CoreVideo

class SmoothScroller {
    private static var displayLink: CVDisplayLink?
    private static let eventSource = CGEventSource(stateID: .hidSystemState)
    private static var deltaY: Int32 = 0
    private static var isStart = false

    static func start(direction: Int32) {
        if isStart {
            return
        }
        deltaY = direction

        if displayLink == nil {
            var link: CVDisplayLink?
            CVDisplayLinkCreateWithActiveCGDisplays(&link)
            if link == nil {
                return
            }
            displayLink = link
        }
        
        let dl = displayLink!

        CVDisplayLinkSetOutputCallback(dl, { _, _, _, _, _, _ in
            SmoothScroller.scroll()
            return kCVReturnSuccess
        }, nil)

        isStart = (CVDisplayLinkStart(dl) == kCVReturnSuccess)
    }

    static func stop() {
        if isStart, let dl = displayLink {
            isStart = (CVDisplayLinkStop(dl) != kCVReturnSuccess)
        }
    }

    static func scroll() {
        scroll(deltaY)
    }
    
    static func scroll(_ deltaY: Int32) {
        let ev = CGEvent(scrollWheelEvent2Source: self.eventSource, units: .pixel, wheelCount: 1, wheel1: deltaY, wheel2: 0, wheel3: 0)
        ev?.post(tap: .cghidEventTap)
    }
    
    static func scrollToTop() {
        stop()
        scroll(Int32.max)
    }

    static func scrollToBottom() {
        stop()
        scroll(Int32.min)
    }
}

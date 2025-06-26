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
    private var displayLink: CVDisplayLink?
    private let eventSource = CGEventSource(stateID: .hidSystemState)
    private var deltaY: Int32 = 0

    func start(direction: Int32) {
        stop()
        deltaY = direction

        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let dl = link else { return }

        displayLink = dl
        CVDisplayLinkSetOutputCallback(dl, { _, _, _, _, _, userInfo in
            let scroller = Unmanaged<SmoothScroller>.fromOpaque(userInfo!).takeUnretainedValue()
            scroller.scroll()
            return kCVReturnSuccess
        }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        CVDisplayLinkStart(dl)
    }

    func stop() {
        if let dl = displayLink {
            CVDisplayLinkStop(dl)
            displayLink = nil
        }
    }

    private func scroll() {
        let event = CGEvent(scrollWheelEvent2Source: eventSource, units: .pixel, wheelCount: 1, wheel1: deltaY, wheel2: 0, wheel3: 0)
        event?.post(tap: .cghidEventTap)
    }
}

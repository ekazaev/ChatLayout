//
//  FPSCounter.swift
//  fps-counter
//
//  Created by Markus Gasser on 03.03.16.
//  Copyright © 2016 konoma GmbH. All rights reserved.
//

import UIKit
import QuartzCore


/// A class that tracks the current FPS of the running application.
///
/// `FPSCounter` uses `CADisplayLink` updates to count the frames per second drawn.
/// Set the delegate of this class to get notified in certain intervals of the
/// current FPS.
///
/// If you just want to see the FPS in the application you can use the
/// `FPSCounter.showInStatusBar()` convenience method.
///
public class FPSCounter: NSObject {

    /// Helper class that relays display link updates to the FPSCounter
    ///
    /// This is necessary because CADisplayLink retains its target. Thus
    /// if the FPSCounter class would be the target of the display link
    /// it would create a retain cycle. The delegate has a weak reference
    /// to its parent FPSCounter, thus preventing this.
    ///
    internal class DisplayLinkProxy: NSObject {

        /// A weak ref to the parent FPSCounter instance.
        @objc weak var parentCounter: FPSCounter?

        /// Notify the parent FPSCounter of a CADisplayLink update.
        ///
        /// This method is automatically called by the CADisplayLink.
        ///
        /// - Parameters:
        ///   - displayLink: The display link that updated
        ///
        @objc func updateFromDisplayLink(_ displayLink: CADisplayLink) {
            parentCounter?.updateFromDisplayLink(displayLink)
        }
    }


    // MARK: - Initialization

    private let displayLink: CADisplayLink
    private let displayLinkProxy: DisplayLinkProxy

    /// Create a new FPSCounter.
    ///
    /// To start receiving FPS updates you need to start tracking with the
    /// `startTracking(inRunLoop:mode:)` method.
    ///
    public override init() {
        self.displayLinkProxy = DisplayLinkProxy()
        self.displayLink = CADisplayLink(
            target: self.displayLinkProxy,
            selector: #selector(DisplayLinkProxy.updateFromDisplayLink(_:))
        )

        super.init()

        self.displayLinkProxy.parentCounter = self
    }

    deinit {
        self.displayLink.invalidate()
    }


    // MARK: - Configuration

    /// The delegate that should receive FPS updates.
    public weak var delegate: FPSCounterDelegate?

    /// Delay between FPS updates. Longer delays mean more averaged FPS numbers.
    @objc public var notificationDelay: TimeInterval = 1.0


    // MARK: - Tracking

    private var runloop: RunLoop?
    private var mode: RunLoop.Mode?

    /// Start tracking FPS updates.
    ///
    /// You can specify wich runloop to use for tracking, as well as the runloop modes.
    /// Usually you'll want the main runloop (default), and either the common run loop modes
    /// (default), or the tracking mode (`RunLoop.Mode.tracking`).
    ///
    /// When the counter is already tracking, it's stopped first.
    ///
    /// - Parameters:
    ///   - runloop: The runloop to start tracking in
    ///   - mode:    The mode(s) to track in the runloop
    ///
    @objc public func startTracking(inRunLoop runloop: RunLoop = .main, mode: RunLoop.Mode = .common) {
        self.stopTracking()

        self.runloop = runloop
        self.mode = mode
        self.displayLink.add(to: runloop, forMode: mode)
    }

    /// Stop tracking FPS updates.
    ///
    /// This method does nothing if the counter is not currently tracking.
    ///
    @objc public func stopTracking() {
        guard let runloop = self.runloop, let mode = self.mode else { return }

        self.displayLink.remove(from: runloop, forMode: mode)
        self.runloop = nil
        self.mode = nil
    }


    // MARK: - Handling Frame Updates

    private var lastNotificationTime: CFAbsoluteTime = 0.0
    private var numberOfFrames = 0

    private func updateFromDisplayLink(_ displayLink: CADisplayLink) {
        if self.lastNotificationTime == 0.0 {
            self.lastNotificationTime = CFAbsoluteTimeGetCurrent()
            return
        }

        self.numberOfFrames += 1

        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = currentTime - self.lastNotificationTime

        if elapsedTime >= self.notificationDelay {
            self.notifyUpdateForElapsedTime(elapsedTime)
            self.lastNotificationTime = 0.0
            self.numberOfFrames = 0
        }
    }

    private func notifyUpdateForElapsedTime(_ elapsedTime: CFAbsoluteTime) {
        let fps = Int(round(Double(self.numberOfFrames) / elapsedTime))
        self.delegate?.fpsCounter(self, didUpdateFramesPerSecond: fps)
    }
}


/// The delegate protocol for the FPSCounter class.
///
/// Implement this protocol if you want to receive updates from a `FPSCounter`.
///
public protocol FPSCounterDelegate: NSObjectProtocol {

    /// Called in regular intervals while the counter is tracking FPS.
    ///
    /// - Parameters:
    ///   - counter: The FPSCounter that sent the update
    ///   - fps:     The current FPS of the application
    ///
    func fpsCounter(_ counter: FPSCounter, didUpdateFramesPerSecond fps: Int)
}

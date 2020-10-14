[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/FPSCounter.svg)](https://cocoapods.org/pods/FPSCounter)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/konoma/fps-counter/blob/master/LICENSE)

# FPSCounter

A small library to measure the frame rate of an iOS Application.

You can display the current frames per second in the status bar with a single line. Or if
you'd like more control, you can have your own code notified of FPS changes and display it
as needed.

_Note_: You should only use this for debugging purposes. Especially the status bar overlay
may cause Apple to reject your app when reviewed.


## Usage

The easiest way to use this library is to add a label to the status bar:

    FPSCounter.showInStatusBar()

This will replace the status bar with a label that shows the current frames per second
the application manages to draw.

You can remove the label any time later:

    FPSCounter.hide()

If you'd like more control on how to display the frames, you can create a private
`FPSCounter` instance and set a delegate

    self.fpsCounter = FPSCounter()
    self.fpsCounter.delegate = self

To retrieve updates you need to start tracking the FPS:

    self.fpsCounter.startTracking()

If necessary you can specify what run loop and run loop mode to use while tracking:

    self.fpsCounter.startTracking(inRunLoop: myRunLoop, mode: .tracking)

By default `RunLoop.main`  and  `RunLoop.Mode.common` are used.

When you don't want to receive further updates, you can stop tracking:

    self.fpsCounter.stopTracking()


## Installation

### Carthage

To install this library via [Carthage](https://github.com/Carthage/Carthage) add the
following to your `Cartfile`:

    github "konoma/fps-counter" ~> 4.0

Then run the standard `carthage update` process.


### CocoaPods

To install this library via [CocoaPods](https://cocoapods.org) add the following to
your `Podfile`:

    pod 'FPSCounter', '~> 4.0'

Then run the standard `pod update` process.


## License

FPSCounter is released under the [MIT License](https://github.com/konoma/fps-counter/blob/master/LICENSE).

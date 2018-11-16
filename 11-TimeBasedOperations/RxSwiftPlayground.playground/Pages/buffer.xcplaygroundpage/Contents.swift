//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa
import PlaygroundSupport


class TimelineView<E>: TimelineViewBase, ObserverType where E: CustomStringConvertible {
    static func make() -> TimelineView<E> {
        let view = TimelineView(frame: CGRect(x: 0, y: 0, width: 400, height: 100))
        view.setup()
        return view
    }
    public func on(_ event: Event<E>) {
        switch event {
        case .next(let value):
            add(.Next(String(describing: value)))
        case .completed:
            add(.Completed())
        case .error(_):
            add(.Error())
        }
    }
}

let elementsPerSecond = 1
let maxElements = 9
let replayedElements = 2
let replayDelay: TimeInterval = 3

var source = ConnectableObservable<Int>.create { observer in
    var value = 1
    let timer = DispatchSource.timer(interval: 1.0/Double(elementsPerSecond), queue: .main) {
        if value <= maxElements {
            observer.onNext(value)
            value = value + 1
        }
    }
    return Disposables.create {
        timer.suspend()
    }
    }.replayAll()

let sourceTimeline = TimelineView<Int>.make()
let replayedTimeline = TimelineView<Int>.make()

let stack = UIStackView.makeVertical([
    UILabel.makeTitle("replay"),
    UILabel.make("Emit \(elementsPerSecond) per second:"),
    sourceTimeline,
    UILabel.make("Replay \(replayedElements) after \(replayDelay) sec:"),
    replayedTimeline
    ])

_ = source.subscribe(sourceTimeline)

DispatchQueue.main.asyncAfter(deadline: .now() + replayDelay) {
    _ = source.subscribe(replayedTimeline)
}


_ = source.connect()

let hostView = setupHostView()
hostView.addSubview(stack)


PlaygroundPage.current.liveView = hostView
PlaygroundPage.current.needsIndefiniteExecution = true


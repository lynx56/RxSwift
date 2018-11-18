//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa
import PlaygroundSupport

let elementsPerSecond = 3
let windowTimespan: RxTimeInterval = 4
let windowMaxCount = 6
let sourceObservable = PublishSubject<String>()

let sourceTimeline = TimelineView<String>.make()

let stack = UIStackView.makeVertical([
    UILabel.makeTitle("window"),
    UILabel.make("Emitted elements (\(elementsPerSecond) per second): "),
    sourceTimeline,
    UILabel.make("Windowed observables (at most \(windowMaxCount) every \(windowTimespan) seconds):")
    ])

let timer = DispatchSource.timer(interval: 1.0/Double(elementsPerSecond), queue: .main) {
    sourceObservable.onNext("🐱")
}

_ = sourceObservable.subscribe(sourceTimeline)
/*
 _ = sourceObservable.window(timeSpan: windowTimespan, count: windowMaxCount, scheduler: MainScheduler.instance).flatMap {
 windowedObservable -> Observable<(TimelineView<Int>, String?)> in
 let timeline = TimelineView<Int>.make()
 stack.insert(timeline, at: 4)
 stack.keep(atMost: 8)
 
 return windowedObservable.map { value in (timeline, value) }
 .concat(Observable.just((timeline,nil)))
 }.subscribe(onNext: { tuple in
 let (timeline, value) = tuple
 if let value = value {
 timeline.add(.Next(value))
 } else {
 timeline.add(.Completed(true))
 }
 })
 */

let windowed = sourceObservable.window(timeSpan: windowTimespan, count: windowMaxCount, scheduler: MainScheduler.instance)

let timelines = windowed.do(onNext: {
    let timeline = TimelineView<Int>.make()
    stack.insert(timeline, at: 4)
    stack.keep(atMost: 8)
}).map { _ in
    stack.arrangedSubviews[4] as! TimelineView<Int>
}

// take one of each, guaranteeing that we get the observable
// produced by window AND the latest timeline view creating
_ = Observable
    .zip(windowedObservable, timelineObservable) { obs, timeline in
        (obs, timeline)
    }
    .flatMap { tuple -> Observable<(TimelineView<Int>, String?)> in
        let obs = tuple.0
        let timeline = tuple.1
        return obs
            .map { value in (timeline, value) }
            .concat(Observable.just((timeline, nil)))
    }
    .subscribe(onNext: { tuple in
        let (timeline, value) = tuple
        if let value = value {
            timeline.add(.Next(value))
        } else {
            timeline.add(.Completed(true))
        }
    })

let hostView = setupHostView()
hostView.addSubview(stack)

PlaygroundPage.current.liveView = hostView
PlaygroundPage.current.needsIndefiniteExecution = true
// Support code -- DO NOT REMOVE
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

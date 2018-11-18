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



let bufferTimeSpan: RxTimeInterval = 13
let bufferMaxCount = 2

let sourceObservable = PublishSubject<String>()

let sourceTimeLine = TimelineView<String>.make()
let bufferedTimeLine = TimelineView<Int>.make()

let stack = UIStackView.makeVertical([
    UILabel.makeTitle("buffer"),
    UILabel.make("Emitted elements:"),
    sourceTimeLine,
    UILabel.make("Buffered elements (at most \(bufferMaxCount) every \(bufferTimeSpan) seconds):"),
    bufferedTimeLine
    ]
)

_ = sourceObservable.subscribe(sourceTimeLine)

sourceObservable.buffer(timeSpan: bufferTimeSpan, count: bufferMaxCount, scheduler: MainScheduler.instance)
    .map { $0.count }
    .subscribe(bufferedTimeLine)

let hostView = setupHostView()
hostView.addSubview(stack)

DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
    sourceObservable.onNext("🐱")
    sourceObservable.onNext("🐱")
    sourceObservable.onNext("🐱")
}


PlaygroundPage.current.liveView = hostView
PlaygroundPage.current.needsIndefiniteExecution = true




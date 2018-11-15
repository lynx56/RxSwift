//: Please build the scheme 'RxSwiftPlayground' first
import UIKit
import RxSwift
import RxCocoa

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
let maxElements = 5
let replayedElements = 1
let replayDelay: TimeInterval = 3

example(of: "") {
    let source = Observable<Int>.create { observer in
        let value = 1
        let timer = DispatchSource.timer(interval: 1.0/Double(elementsPerSecond), queue: .main) {
            if value <= maxElements {
               observer.onNext(value)
                value += 1
            }
        }
        return Disposables.create {
            timer.suspend()
        }
    }
    
    source.replay(replayedElements)
}

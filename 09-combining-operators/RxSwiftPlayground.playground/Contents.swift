import RxSwift
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

example(of: "startWith") {
    let numbers = Observable.of(2,3,4)
    let bag = DisposeBag()
    
    let observable = numbers.startWith(1)
    
    observable.subscribe(onNext: { value in
        print(value)
    }).disposed(by: bag)
}

example(of: "static concat") {
    let first = Observable.of(1,2,3)
    let second = Observable.of(4,5,6)
    
    let observable = Observable.concat([first, second])
    
    observable.subscribe(onNext: { value in
        print(value)
    })
}

example(of: "concat") {
    let spanishCities = Observable.of("Madrid", "Barcelona", "Valencia")
    let germanCities = Observable.of("Berlin", "Münich", "Frankfurt")
    
    let mixCities = spanishCities.concat(germanCities)
    
    mixCities.subscribe(onNext: { value in
        print(value)
    })
}

example(of: "concatMap") {
    let countries = [
        "Germany": Observable.of("Berlin", "Münich", "Frankfurt"),
        "Spain": Observable.of("Madrid", "Barcelona", "Valencia")]
    
    let observableCountries = Observable.of("Germany", "Spain").concatMap { country in
        countries[country] ?? .empty()
    }
    
    _ = observableCountries.subscribe(onNext: { city in
        print(city)
    })
}

example(of: "merge") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    let source = Observable.of(left.asObservable(), right.asObservable())
    
    let observable = source.merge()
    _ = observable.subscribe(onNext: {
        value in
        print(value)
    })
    
    left.onNext("1")
    right.onNext("4")
    right.onNext("5")
    left.onNext("2")
    right.onNext("6")
    left.onNext("3")
}

example(of: "combineLatest") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    let observable = Observable.combineLatest(left, right, resultSelector: { lastLeft, lastRight in
        "\(lastLeft) \(lastRight)"
    })
    
    let subscriber = observable.subscribe(onNext: { val in
        print(val)
    })
    
    left.onNext("Hello,")
    right.onNext("world")
    right.onNext("RxSwift")
    left.onNext("Have a good day,")
    
    subscriber.dispose()
}

example(of: "combine userchoice and value") {
    let userChoiceFormat = Observable<DateFormatter.Style>.of(.short, .long)
    let date = Observable<Date>.of(Date())
    
    let userChoiceTimed = Observable.combineLatest(userChoiceFormat, date) { (format, when) -> String in
        let formatter = DateFormatter()
        formatter.dateStyle = format
        return formatter.string(from: when)
    }
    
    userChoiceTimed.subscribe(onNext: { value in
            print(value)
    })
}

example(of: "zip") {
    enum Weather {
        case cloudy
        case sunny
    }
    
    let left: Observable<Weather> = Observable.of(.sunny, .cloudy, .cloudy, .sunny)
    let right = Observable.of("Lisbon", "Copenhagen", "London", "Madrid", "Vienna")
    
    let observable = Observable.zip(left, right) {
        (weather, city) in
        "It's \(weather) in \(city)"
    }
    
    observable.subscribe(onNext: { value in
        print(value)
    })
}

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

/*
 Don’t forget that withLatestFrom(_:) takes the data observable as a parameter, while sample(_:) takes the trigger observable as a parameter.
 */
example(of: "withLatestFrom") {
    let textfield = PublishSubject<String>()
    let button = PublishSubject<Void>()
    
    let observable = button.withLatestFrom(textfield)
    
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
    
    textfield.onNext("Par")
    textfield.onNext("Pari")
    textfield.onNext("Paris")
    
    button.onNext(())
    button.onNext(())
}

example(of: "sample") {
    let textfield = PublishSubject<String>()
    let button = PublishSubject<Void>()
    
    let observable = textfield.sample(button)
    
    _ = observable.subscribe(onNext: { value in
        print(value)
    })
    
    textfield.onNext("Par")
    textfield.onNext("Pari")
    textfield.onNext("Paris")
    
    button.onNext(())
    button.onNext(())
}

example(of: "amb") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    
    let observable = left.amb(right)
    let disposable = observable.subscribe(onNext: {
        value in print(value)
    })

    left.onNext("Lisbon")
    right.onNext("Copenhagen")
    left.onNext("London")
    left.onNext("Madrid")
    right.onNext("Vienna")
    
    disposable.dispose()
}

example(of: "switchLatest") {
    let one = PublishSubject<String>()
    let two = PublishSubject<String>()
    let three = PublishSubject<String>()
    
    let source = PublishSubject<Observable<String>>()
    
    let observable = source.switchLatest()
    let disposable = observable.subscribe(onNext: {
        value in print(value)
    })
    
    source.onNext(one)
    one.onNext("Some text from sequence one")
    two.onNext("Some text from sequence two")
    
    source.onNext(two)
    two.onNext("More text from sequence two")
    one.onNext("and also from sequence one")
    
    source.onNext(three)
    two.onNext("Why don't you see me?")
    one.onNext("I'm alone, help me")
    three.onNext("Hey it's three. I win.")
    
    source.onNext(one)
    one.onNext("Nope. It's me, one!")
    
    disposable.dispose()
}

example(of: "reduce") {
    let source = Observable.of(1, 3, 5, 7, 9)
    
    let observable = source.reduce(0, accumulator: +)
    
    observable.subscribe(onNext: {
        value in print(value)
    })
    /*
        Value only when the source observable completes. Applying this operator to sequences that never complete won’t emit anything. This is a frequent source of confusion and hidden problems.
     */
}

example(of: "scan") {
    let source = Observable.of(1, 3, 5, 7, 9)
    
    let observable = source.scan(0, accumulator: +)
    observable.subscribe(onNext: {
        value in print(value)
    })
}

example(of: "scan and accumulate") {
    let source = Observable.of(1, 3, 5, 7, 9)
    
    let observable = source.scan(0, accumulator: +)
    
    observable.subscribe(onNext: {
        value in print(value)
    })
}

example(of: "scan and zip") {
    let source = Observable.of(1, 3, 5, 7, 9)
    
    let scanObservable = source.scan(0, accumulator: +)
    
    let observable = Observable.zip(source, scanObservable) { value, runningTotal in
        (value, runningTotal)
    }
    
    observable.subscribe(onNext: { tuple
        in print("Value = \(tuple.0) Total = \(tuple.1)")
    })
}

example(of: "scan and tuple") {
    let source = Observable.of(1, 3, 5, 7, 9)
    
    let observable = source.scan((0,0)) { acc, current in
        return (current, acc.1 + current)
    }
    
    observable.subscribe(onNext: { tuple
        in print("Value = \(tuple.0) Total = \(tuple.1)")
    })
}

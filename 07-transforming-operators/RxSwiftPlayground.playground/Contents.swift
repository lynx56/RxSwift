//: Please build the scheme 'RxSwiftPlayground' first
import RxSwift

example(of: "map") {
    let disposeBag = DisposeBag()
    
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    Observable<NSNumber>.of(123, 4, 56).map {
        formatter.string(from: $0) ?? ""
        }.subscribe(onNext: {
            print($0)
        }).disposed(by: disposeBag)
}

example(of: "enumerated and map") {
    let disposeBag = DisposeBag()
    
    Observable.of(1,2,3,4,5,6)
        .enumerated()
        .map { index, integer in
            index > 2 ? integer * 2 : integer
        }.subscribe(onNext: {
            print($0)
    }).disposed(by: disposeBag)
}

struct Student {
    var score: BehaviorSubject<Int>
}

example(of: "flatMap") {
    let disposedBag = DisposeBag()
    
    let ryan = Student(score: BehaviorSubject<Int>(value: 80))
    let charlotte = Student(score: BehaviorSubject<Int>(value: 90))
    
    let student = PublishSubject<Student>()
    
    student.flatMap {
        $0.score
        }.subscribe(onNext: {
            print($0)
    }).disposed(by: disposedBag)
    
    student.onNext(ryan)
    
    ryan.score.onNext(85)
    
    student.onNext(charlotte)
    
    ryan.score.onNext(95)
    
    charlotte.score.onNext(100)
}

example(of: "flatMapLatest") {
    let disposedBag = DisposeBag()
    
    let ryan = Student(score: BehaviorSubject<Int>(value: 80))
    let charlotte = Student(score: BehaviorSubject<Int>(value: 90))
    
    let student = PublishSubject<Student>()
    
    student.flatMapLatest {
        $0.score
        }.subscribe(onNext: {
            print($0)
        }).disposed(by: disposedBag)
    
    student.onNext(ryan)
    
    ryan.score.onNext(85)
    
    student.onNext(charlotte)
    
    ryan.score.onNext(95)
    
    charlotte.score.onNext(100)
}

example(of: "Challenge 1") {
    
    let disposeBag = DisposeBag()
    
    let contacts = [
        "603-555-1212": "Florent",
        "212-555-1212": "Junior",
        "408-555-1212": "Marin",
        "617-555-1212": "Scott"
    ]
    
    let convert: (String) -> UInt? = { value in
        if let number = UInt(value), number < 10 {
            return number
        }
        
        let keyMap: [String:UInt] = [
            "abc": 2, "def": 3, "ghi": 4,
            "jkl": 5, "mno": 6, "prqs": 7,
            "tuv": 8, "wxyz": 9
        ]
        
        let converted = keyMap.filter { $0.key.contains(value) }
            .map { $0.value }.first
        
        return converted
    }
    
    let format: ([UInt]) -> String = {
        var phone = $0.map(String.init).joined()
        
        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 3)
        )
        
        phone.insert("-", at: phone.index(
            phone.startIndex,
            offsetBy: 7)
        )
        
        return phone
    }
    
    let dial: (String) -> String = {
        if let contact = contacts[$0] {
            return "Dialing \(contact) (\($0))..."
        } else {
            return "Contact not found"
        }
    }
    
    let input = Variable<String>("")
    
    // Add your code here
    input.asObservable()
        .map(convert)
        .flatMap{ $0 == nil ? Observable.empty() : Observable.just($0!) }
        .skipWhile { $0 == 0 }
        .take(10)
        .toArray()
        .map(format)
        .map(dial)
        .subscribe(onNext: {
            print($0)
        })
        .disposed(by: disposeBag)
    
    input.value = ""
    input.value = "0"
    input.value = "408"
    
    input.value = "6"
    input.value = ""
    input.value = "0"
    input.value = "3"
    
    "JKL1A1B".forEach {
        input.value = "\($0)"
    }
    
    input.value = "9"
}

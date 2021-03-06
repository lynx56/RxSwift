//: Please build the scheme 'RxSwiftPlayground' first
import RxSwift

example(of: "Variable") {
  
  enum UserSession {
    case loggedIn
    case loggedOut
  }
  
  enum LoginError: Error {
    case invalidCredentials
  }
  
  let disposeBag = DisposeBag()
  
    let userSession = Variable<UserSession>(.loggedOut)
 
    userSession.asObservable().subscribe(
        onNext: {
            if $0 == .loggedIn{
            performActionRequiringLoggedInUser {
             print("Successfully did something only a logged in user can do.")
             }
            }
    },
        onError: { print($0) },
        onCompleted: { print("Completed") },
        onDisposed: { print("Disposed") })
        .disposed(by: disposeBag)
  
    func logInWith(username: String, password: String, completion: (Error?) -> Void) {
        guard username == "johnny@appleseed.com",   password == "appleseed"
            else {
                completion(LoginError.invalidCredentials)
                return
        }
    
        userSession.value = .loggedIn
  }
  
  func logOut() {
    userSession.value = .loggedOut
  }
  
  func performActionRequiringLoggedInUser(_ action: () -> Void) {
    if userSession.value == .loggedIn {
        action()
    }
  }
  
  for i in 1...2 {
    let password = i % 2 == 0 ? "appleseed" : "password"
    
    logInWith(username: "johnny@appleseed.com", password: password) { error in
      guard error == nil else {
        print(error!)
        return
      }
      
      print("User logged in.")
    }
    
   // performActionRequiringLoggedInUser {
     // print("Successfully did something only a logged in user can do.")
   // }
  }
}

/*:
 Copyright (c) 2014-2017 Razeware LLC
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

//: Please build the scheme 'RxSwiftPlayground' first
import RxSwift

// Subject是可以充当 observable 和 observer.
// 在 RxSwift 有四种类型的 subject
// * PublishSubject: 以 空 开始仅仅发送新的元素给订阅者
// * BehaviorSubject: 以一个初始值开始, 重放它(立即发送它?)或者以最新的元素给订阅者
// * ReplaySunject: 初始化一个缓冲区大小, 并将保存元素到缓冲区直至填满,然后重放给新的订阅者
// * Variable: 包装一个 BehaviorSubject, 保存现在的值为一个状态, 仅仅将最新的或者初始值 给订阅者

    // 使用 PublishSubject
example(of: "PublishSubject") {

    //当你只是想要订阅用户从他们订阅的时间点收到新事件的通知时，发布主题就会派上用场，直到他们取消订阅，或者这个主题已经终止了。或者发出错误的事件。
    //创建 发布主题
    let subject = PublishSubject<String>()
    subject.onNext("Is anyone listening")//此时不会有任何输出
    let subscriptionOne = subject.subscribe(onNext:{
        //此时仍然不会有任何输出,因为PublishSubject 仅仅发送给现有的subscribers
        print($0)
    })
    subject.on(.next("1"))//subject.onNext 简写
    subject.onNext("2")
    let subscriptionTwo = subject.subscribe{ event in
        print("2)", event.element ?? event)
    }
    
    subject.onNext("3")
    
    subscriptionOne.dispose()
    subject.onNext("4")// one 收不到事件了
    
    subject.onCompleted()
    subject.onNext("5")// 已结束 收不到 5
    // subject.onCompleted() 会发送事件至 新的订阅者 事实上所有的subjuct都会发送onCompleted给未来的订阅者
    subscriptionTwo.dispose()
    
    let disposeBag = DisposeBag()
    
    subject.subscribe{
        print("3)", $0.element ?? $0)
    }.addDisposableTo(disposeBag)
    subject.onNext("?")

}


//使用BehaviorSubjects
//BehaviorSubjects 和 PublishSubject相似 但它会重演最新的值给订阅者(直接发送当前值给订阅者)

enum MyError: Error {
    case anError
}
func print<T: CustomStringConvertible>(label: String, event: Event<T>){
    print(label, event.element ?? event.error ?? event)
}
example(of: "BehaviorSubject") {
    // BehaviorSubjects 在预填充最新数据的页面非常有用
    let subject = BehaviorSubject(value: "Initial value")
    let disposBag = DisposeBag()
    
    subject.subscribe{
        print(label: "1)", event: $0)
    }
        .addDisposableTo(disposBag)
    subject.onNext("X")
    
    subject.onError(MyError.anError)
    subject.subscribe{
        print(label: "2)", event: $0)
    }
    .addDisposableTo(disposBag)
    
    
}


// 使用 ReplaySubjects
// ReplaySubjects 将暂时地缓存或缓冲最新的发出的元素直到达到所指定的空间大小,它将重演那些缓存给(最新的)订阅者
// 谨记,当使用ReplaySubjects时它的缓存是保持在内存当中,如果不小心将很容易造成内存压力.(例如实例包含大量图片,或大空间的数组)
example(of: "ReplaySubjects") {
    let subject = ReplaySubject<String>.create(bufferSize: 2)
    let disposeBag = DisposeBag()
    subject.onNext("1")
    subject.onNext("2")
    subject.onNext("3")
    subject.subscribe{
        print(label: "1)", event: $0)
    }
    .addDisposableTo(disposeBag)
    subject.subscribe{
        print(label: "2)", event: $0)
    }
    .addDisposableTo(disposeBag)
    subject.onNext("4")
    //-- 在创建 3) 之前发送 error事件--begin
    //即使发出error事件 订阅终止 但缓存区仍存在,因此还会发送缓存区数据给最新的订阅者,最后也会收到error事件
    subject.onError(MyError.anError)
    //subject.dispose()// 如若执行清除,则不会收到缓存区数据但会收到"Object `RxSwift.ReplayMany<Swift.String>` was already disposed."
    subject.subscribe{
        print(label: "3)", event: $0)
    }
    .addDisposableTo(disposeBag)
    
    subject.onError(MyError.anError)
    //-- 在创建 3) 之前发送 error事件--end
    
}

//使用 Variables
// 包装一个 BehaviorSubject, 保存现在的值为一个状态, 仅仅将最新的或者初始值 给订阅者, 可以使用 value 属性访问它现在的值,不同于其他的Subjects 和 observables, 你不能使用 onNext 发送新的元素, 你也须使用 value 属性来设置新的属性给 Variables. 可以调用 asObservable() 来访问包装在其之下的 behavior subject.
// Variables 保证不发出error事件 , 因此尽管你可以在subscription监听,error事件 但你不能添加.error在 variable之上.variable将会自动发出 complete 事件,当其将要被回收,所以也不能添加.completed

example(of: "Variable") {
    var variable = Variable("Initial value")
    let disposeBag = DisposeBag()
    variable.value = "New initial value"
    variable.asObservable().subscribe{
        print(label: "1)", event: $0)
    }
    .addDisposableTo(disposeBag)
    variable.value = "1"
    variable.asObservable().subscribe{
        print(label: "2)", event: $0)
    }
    .addDisposableTo(disposeBag)
    variable.value = "2"
    /*
     // These will all generate errors
     variable.value.onError(MyError.anError)
     
     variable.asObservable().onError(MyError.anError)
     
     variable.value = MyError.anError
     
     variable.value.onCompleted()
     
     variable.asObservable().onCompleted()
     */
}

example(of: "challenges 1: 使用PublishSubject创建21点牌经销商") {
    
    let disposeBag = DisposeBag()
    
    let dealtHand = PublishSubject<[(String, Int)]>()
    
    func deal(_ cardCount: UInt) {
        var deck = cards
        var cardsRemaining: UInt32 = 52
        var hand = [(String, Int)]()
        
        for _ in 0..<cardCount {
            let randomIndex = Int(arc4random_uniform(cardsRemaining))
            hand.append(deck[randomIndex])
            deck.remove(at: randomIndex)
            cardsRemaining -= 1
        }
        
        // Add code to update dealtHand here
        if points(for: hand) > 21 {
            dealtHand.onError(HandError.busted)
        } else {
            dealtHand.onNext(hand)
        }
    }
    
    // Add subscription to dealtHand here
    dealtHand
        .subscribe(
            onNext: {
                print(cardString(for: $0), "for", points(for: $0), "points")
        },
            onError: {
                print(String(describing: $0).capitalized)
        })
        .addDisposableTo(disposeBag)
    
    deal(2)
}
example(of: "challenges 2 使用Variable检查用户会话") {
    
    enum UserSession {
        
        case loggedIn, loggedOut
    }
    
    enum LoginError: Error {
        
        case invalidCredentials
    }
    
    let disposeBag = DisposeBag()
    
    // Create userSession Variable of type UserSession with initial value of .loggedOut
    var userSession = Variable<UserSession>(UserSession.loggedOut)
    
    // Subscribe to receive next events from userSession
    userSession.asObservable().subscribe(onNext:{
        print($0)
    }).addDisposableTo(disposeBag)
    
    func logInWith(username: String, password: String, completion: (Error?) -> Void) {
        guard username == "johnny@appleseed.com",
            password == "appleseed"
            else {
                completion(LoginError.invalidCredentials)
                return
        }
        
        // Update userSession
        userSession.value = UserSession.loggedIn
    }
    
    func logOut() {
        // Update userSession
        userSession.value = UserSession.loggedOut
    }
    
    func performActionRequiringLoggedInUser(_ action: () -> Void) {
        // Ensure that userSession is loggedIn and then execute action()
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
        
        performActionRequiringLoggedInUser {
            print("Successfully did something only a logged in user can do.")
        }
    }
}
let numbers = Observable<Int>.create { observer in
    let start = getStartNumber()
    observer.onNext(start)
    observer.onNext(start+1)
    observer.onNext(start+2)
    observer.onCompleted()
    return Disposables.create()
}
var start = 0
func getStartNumber() -> Int {
    start += 1
    return start
}
numbers.subscribe(onNext: { el in print("element [\(el)]") }, onCompleted: {
        print("-------------")
})
numbers.subscribe(onNext: { el in print("element [\(el)]") }, onCompleted: {
    print("-------------")
})


//: Please build the scheme 'RxSwiftPlayground' first
import RxSwift

example(of: "just, of, from") {
    let one = 1
    let two = 2
    let three = 3
    //由单个数据创建 observable
    let observable: Observable<Int> = Observable<Int>.just(one)
    //传入多个数据, 参数为可变参数 因此数据类型同参数类型 Observable<Int>
    let observable2 = Observable.of(one, two, three)
    //传入数组,因此数据类型同参数类型 Observable<Int>
    let obseervable3 = Observable.of([one, two, three])
    //传入数组, 数据类型为 Observable<[Int]>
    let observable4 = Observable.from([one, two, three])
    //文档中关于 API的解释 Just类似于From，但是From会将数组或Iterable的数据取出然后逐个发射，而Just只是简单的原样发射，将数组或Iterable当做单个数据。
    
    //类比Swift中的 NotificationCenter 和 sequence
    let observer = NotificationCenter.default.addObserver(forName: .UIKeyboardDidChangeFrame, object: nil, queue: nil, using: { (notification) in
        
    })
    
    let sequence = 0..<3
    var iterator = sequence.makeIterator()
    while let n = iterator.next() {
        print(n)
    }
    // Subscribing
    example(of: "Subscribing", action: {
        let one = 1
        let two = 2
        let three = 3
        // observable 为每个元素发出next事件,但结束时 发送.completed事件
        let observable = Observable.of(one, two, three)
        observable.subscribe({ (event) in
            print(event)
            if let element = event.element {
                print(element)
            }
        })
        
        //observable 可发出 .next, .error, and .completed events. 上面的是接受所有的event, 也可指定event
        observable.subscribe(onNext:{element in
            print(element)
        })
        

    })
    
    example(of: "empty", action: {
        //可以使用 empty 操作符创建一个空的 observable, 订阅它将接收到 onCompleted
        //empty的用途在于创建一个立即结束的或者有意创建没有元素的observable
        let observable = Observable<Void>.empty()
        
        observable
            .subscribe(
                
                onNext: { element in
                    print(element)
            },
                onCompleted: {
                    print("Completed")
            }
        )
        
    })
    
    
    example(of: "never", action: {
        //创建不会发出任何事件的 observable
        let observable = Observable<Any>.never()
        observable.subscribe(
            onNext: { element in
                print(element)
            },
            onCompleted:{
                print("Completed")
            }
        )
        
    })
    
    example(of: "range", action: {
        //由 range 型数据创建 observable
        let observable = Observable<Int>.range(start: 1, count: 10)
        observable.subscribe(onNext: { i in
            let n = Double(i)
            let fibonacci = Int(((pow(1.61803, n) - pow(0.61803, n)) / 2.23606).rounded())
            print(fibonacci)

        })
    })
    
    example(of: "dispose", action: {
        let observable = Observable.of("A", "B", "C")
        let subscription = observable.subscribe({ event in
            print(event)
        })
        //调用 dispose() 来清除订阅
        subscription.dispose()
        
    })
    
    example(of: "DisposeBag", action: {
        let disposeBag = DisposeBag()
        Observable.of("A", "B", "C").subscribe {
                print($0)
        }.addDisposableTo(disposeBag)
        
    })
    
    //使用create指定一个observable的所有将要发送给订阅者的事件
    enum MyError: Error{
        case anError
    }
    example(of: "create", action: {
        let disposBag = DisposeBag()
        //create操作携带一个名为subscribe的参数,通过此参数可定义所有的要发送给订阅者的事件
        Observable<String>.create({observer in
            observer.onNext("1")
            observer.onError(MyError.anError)
            observer.onCompleted()
            observer.onNext("?")
            //返回一个可清除的对象
            //相当于 subscription, create是一个空的disposable, 但其他Disposables可能有一些副作用
            return Disposables.create()
        }).subscribe(
            onNext:{
                print($0)
            },onError:{
                print($0)
            },onCompleted:{
                print("completed")
            },onDisposed:{
                print("disposed")
            }).addDisposableTo(disposBag)
        
        //如果注释掉 observer的 onError 和 onCompleted, addDisposableTo(), name就会造成内存泄漏 observable 将不会停止 disposable也不会清除它
    })
    
    
    //与其创建一个等待订阅者的 observable,还可以创建observable 工厂,为每个订阅者提供新的observable
    example(of: "defferred", action: {
        let disposeBag = DisposeBag()
        //1. Create a Bool flag to flip which observable to return.
        var flip = false
        //2. Create an observable of Int factory using the deferred operator.
        let factory: Observable<Int> = Observable.deferred{
            //3. Invert flip, which will be used each time factory is subscribed to.
            flip = !flip
            //4. Return different observables based on if flip is true or false
            if flip {
                return Observable.of(1, 2, 3)
            } else {
                return Observable.of(4, 5, 6)
            }
        }
        // 每一次订阅就会得到相反的 Observable
        for _ in 0...3 {
            factory.subscribe(onNext:{
                print($0, terminator:"")
            })
            .addDisposableTo(disposeBag)
            print()
        }
    })
    
    //TODO: Challenges😆
    //1. 展示副作用: 之前的 "never" 示例没有任何输出,即使将它addDisposableTo()也不会收到 onDisposed. 有一个有用的操作符可以做一些"副作用"且不影响observable. "do" 操作符允许你插入side effects
    //疑问: 所谓的 side effects 类似于一个通知自己 "被订阅" 的回调事件???
    //To complete this challenge, insert use of the do operator in the never example using the onSubscribe handler. Feel free to include any of the other handlers if you’d like; they work just like subscribe’s handlers do.
    example(of: "never Challenges do", action: {
        let disposeBag = DisposeBag()
        let observable = Observable<Any>.never()
        observable.do(onSubscribe:{print("Subscribed")})
            .subscribe(
                onNext: { element in
                    print(element)
            },
                onCompleted: {
                    print("Completed")
            },
                onDisposed: {
                    print("Disposed")
            }
            )
            .addDisposableTo(disposeBag)
    })
    
    //使用do 可以帮助我们debug RX, 但有一个更好的工具可以达到这个目的,那就是 debug操作符,他可以打印observable的每个事件的信息,他有一系列有用的参数,可能最有用的是它可以包含一个唯一标识字符串可以被打印在每一行
    // 替换 do为 debug然后提供一个唯一标识字符串
    example(of: "never chanllage debug", action: {
        let disposeBag = DisposeBag()
        let observable = Observable<Any>.never()
        observable.debug("idbiubiubiu")
            .subscribe(
                onNext: { element in
                    print(element)
            },
                onCompleted: {
                    print("Completed")
            },
                onDisposed: {
                    print("Disposed")
            }
            )
            .addDisposableTo(disposeBag)
        
    })
}











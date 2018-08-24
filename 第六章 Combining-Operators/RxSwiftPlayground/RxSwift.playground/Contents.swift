//: Please build the scheme 'RxSwiftPlayground' first
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
   
import RxSwift
// conbin observable
//以...开始
example(of: "startWith") {
    let numbers = Observable.of(2, 3, 4)
    let observable = numbers.startWith(1)
    observable.subscribe(onNext: { value in
        print(value)
    })
}
// 使用 静态方法 Observable.concat 结合两个 Observable
example(of: "Observable.concat") {
    let first = Observable.of(1, 2, 3)
    let second = Observable.of(4, 5, 6)
    let observable = Observable.concat([first,second])
    observable.subscribe(onNext: { value in
        print(value)
    })
    
}

// 使用实例方法  concat 结合两个 Observable
example(of: "concat") {
    let germanCities = Observable.of("Berlin", "Münich", "Frankfurt")
    let spanishCities = Observable.of("Madrid", "Barcelona", "Valencia")
    let observable = germanCities.concat(spanishCities)
    observable.subscribe(onNext: { value in
        print(value)
    })
    
    
    

}

//startWith 也可用 concat 改装

example(of: "concat one element") {
    let numbers = Observable.of(2, 3, 4)
    let observable = Observable.just(1).concat(numbers)
    observable.subscribe(onNext: { value in
        print(value)
        
    })
    
}

// rx 提供一些方法 可以 combine 序列(Subject), 最简单的方式 就是使用 merge

example(of: "merge") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    //将两个 subject下的 observalbe 包装起来 然后调用merge方法
    
    let source = Observable.of(left.asObservable(), right.asObservable())
    //一个 merge observable  subscribes(订阅) 每个序列, 当它一接收到元素会发射它们
    let observable = source.merge(maxConcurrent: 1)
    let disposable = observable.subscribe(onNext: { value in
        print(value)
        
    })
    //发射元素
    var leftValues = ["Berlin", "Munich", "Frankfurt"]
    var rightValues = ["Madrid", "Barcelona", "Valencia"]
    repeat {
        if arc4random_uniform(2) == 0 {
            if !leftValues.isEmpty {
                left.onNext("left: " + leftValues.removeFirst())
            }
        } else if !rightValues.isEmpty {
            right.onNext("right: " + rightValues.removeFirst())
        }
    } while !leftValues.isEmpty || !rightValues.isEmpty
    
    disposable.dispose()
    // merge() 如何 complete
    // 1. merge()会在它的源序列完成 以及 所有的内部序列完成时 它也会完成
    // 2. 内部的序列结束顺序是无关紧要的
    // 3. 如果所有的序列 发送了 error, merge()会立即触发error 然后终止
    
    
    // 可以看到source.merge()时source包含了两个 observable 的 observable, 事实上它也可以包含多个来调用merge(). 若要限制一次订阅的序列个数, 可以使用 merge(maxConcurrent:) 这个方法可以保留订阅将要到来的序列 直到它达到最大并发数 在此之后 它将将要到来的 observables 放到一个队列, 它将按顺序订阅他们, 直到其中一个当前序列 完成
    
}


// 在rxswift中最常用的操作符组之一就有 combineLatest家族
//每次其中之一的序列(PublishSubject)发射出一个值,它就执行你所提供的闭包. 你接收来自其中每一个序列的最后一个值(每个序列必须已拥有一个值)
example(of: "combineLatest") {
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
//    let test = PublishSubject<String>()
// 就像 map(_:) 那样combineLatest(_:_:resultSelector:) 创建了一个observable 类型是这个闭包的returntype
    let observable = Observable.combineLatest(left, right, resultSelector: { (lastLeft, lastRight) in
        "\(lastLeft, lastRight)"
    })
    let disposable = observable.subscribe(onNext: { value in
        print(value)
        
    })
    // 如果是三个subject combinlast  test 没有发出 则 尽管 left right有值也不行
    //Remember that combineLatest(_:_:resultSelector:) waits for all its observables to emit one element before starting to call your closure. It’s a frequent source of confusion and a good opportunity to use the startWith(_:) operator to provide an initial value for the sequences, which could take time to update.
    print("> Sending a value to Left")
    left.onNext("Hello,")
    print("> Sending a value to Right")
    right.onNext("world")
    print("> Sending another value to Right")
    right.onNext("RxSwift")
    print("> Sending another value to Left")
    left.onNext("Have a good day,")
    disposable.dispose()
    
}
// combineLatest操作的 序列可以是不同的类型
example(of: "combine user choice and value") {
    let choice : Observable<DateFormatter.Style> = Observable.of(.short, .long)
    let dates = Observable.of(Date())
    let observable = Observable.combineLatest(choice, dates, resultSelector: { (format, when) -> String  in
        let formatter = DateFormatter()
        formatter.dateStyle = format
        return formatter.string(from: when)
    })
    
    observable.subscribe(onNext: {value in
        print(value)
    })
    //还有一个很少用的变体 它接受一个集合combineLatest(_:_:resultSelector:) 但它限制集合中的元素必须是同一类型
    
//    let observable = Observable.combineLatest([left, right]) { strings in strings.joined(separator: " ") }
    
    //最后 combineLates 仅仅在其中最后一个序列完成 才会结束
    
}
// d
example(of: "zip") {
    enum Weather {
        case cloudy
        case sunny
    }
    let left : Observable<Weather> = Observable.of(.sunny, .cloudy, .cloudy, .sunny)
    let right = Observable.of("Lisbon", "Copenhagen", "London", "Madrid", "Vienna")
    //等待每个序列发送新值(1-1 2-2  不会发 1-2) 然后执行闭包 当其中之一 完成 则zip也会 complete
    let observable = Observable.zip(left, right, resultSelector: { (weather, city) -> String in
        return "it's \(weather) in \(city)"
    })
    observable.subscribe(onNext:{
        print($0)
    })
    
}
//Triggers (触发事件 如 tap)
//withLatestFrom(_:) 初学者经常忽略 经常用于用户交互
example(of: "withLatestFrom") {
    //它很有用特别是在需要特殊的时机(如触摸, 点击等)触发事件时来获取最新的值
    // 1
    let button = PublishSubject<Void>()
    let textField = PublishSubject<String>()
    
    // 2
//    let observable = button.withLatestFrom(textField)
    //sample 与  withLatestFrom相近 唯一的不同时, 每次的触发事件只会发送最新的值, 当两次触发事件之间没有最新的值更新的话就不会发射元素, 这个与 button.withLatestFrom(textField).distinctUntilChanged()
    
    let observable = textField.sample(button)
    
    
    
    let disposable = observable.subscribe(onNext: { value in print(value)
        
    })
    
    // 3
    textField.onNext("Par")
    textField.onNext("Pari")
    textField.onNext("Paris")
    //点击btn时候(发射值)时, 会忽略它并发射textfiled的最新值来代替
    button.onNext(())
    button.onNext(())//simple 时 只会打印一个 "Paris"

}

//Switches 切换
//rxswift 中有两个 switching 操作符 amb(_:) 和 switchLatest()它们可以选择subscriber接受某个 combined or source sequences 中的确切observable的事件
example(of: "amb") {//ambiguity
    
    
    let left = PublishSubject<String>()
    let right = PublishSubject<String>()
    // amb 操作符订阅 left 和 right 等待其中之一发射元素 然后 取消订阅另一个. 谁先来就选择谁
    let observable = left.amb(right)
    let disposable = observable.subscribe(onNext: {
        print($0)
    })
    
    left.onNext("Lisbon")
    right.onNext("Copenhagen")
    left.onNext("London")
    left.onNext("Madrid")
    right.onNext("Vienna")
    disposable.dispose()
    
    
}
//switchLatest()  订阅源序列中最新的值
example(of: "switchLatest") {
    let one = PublishSubject<String>()
    let two = PublishSubject<String>()
    let three = PublishSubject<String>()
    //源 Observable序列
    let source = PublishSubject<Observable<String>>()
    //使用 switchLatest() 订阅源序列中最新的值
    let observable = source.switchLatest()
    let disposable = observable.subscribe(onNext: { value in print(value) })
    //切换
    source.onNext(one)
    one.onNext("Some text from sequence one")
    two.onNext("Some text from sequence two")
    
    source.onNext(two)
    two.onNext("More text from sequence two")
    one.onNext("and also from sequence one")
    
    source.onNext(three)
    two.onNext("Why don't you seem me?")
    one.onNext("I'm alone, help me")
    three.onNext("Hey it's three. I win.")
    
    source.onNext(one)
    one.onNext("Nope. It's me, one!")
    disposable.dispose()
}


//处理序列(Observable)中内部元素
//reduce 缩短 类似swift中的 reduce() 函数
example(of: "reduce") {
    let source = Observable.of(1, 3, 5, 7, 9)
    //以数字0起始累加每个元素 会在源 complete 时 执行 onNext,发射值的类型为 accumulator参数的返回值 若源Observable没有结束则 不会做任何事
    let observable = source.reduce(0, accumulator: +)
    observable.subscribe(onNext: {
        print($0)
    })
  
}
// scan 与 reduce相似, 但scan会在每次收到源序列发出的元素时 执行onNext
example(of: "scan") {
    let source = Observable.of(1, 3, 5, 7, 9)
    //以数字0起始每收到一个值,累加每个元素 发射值的类型为 accumulator参数的返回值  执行 onNext
    let observable = source.scan(0, accumulator: +)
    
    
    
    observable.subscribe(onNext: {
        print($0)
    })
    
    
    let observableZip = Observable.zip(source, observable, resultSelector: { (x, y) in
        return "\(x) \(y)"
    })
    let observableCombineLatest = Observable.combineLatest(source, observable, resultSelector: { (x, y) in
        return "\(x) \(y)"
    })
    
    observableZip.subscribe(onNext:{
        print($0)
    }).dispose()
    observableCombineLatest.subscribe(onNext:{
        print($0)
    }).dispose()
}



























/*:
 Copyright (c) 2014-2016 Razeware LLC
 
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

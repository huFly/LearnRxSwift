//: Please build the scheme 'RxSwiftPlayground' first
import RxSwift

// Filterig Operators
//Ignoring operators
    //使用 `ignoreElements` 操作符可以忽略元素(next 事件), 除了停止事件(.completed .error)
example(of: "ignoreElement") {
    let strikes = PublishSubject<String>()
    let disposeBag = DisposeBag()
    strikes
        .ignoreElements()
        .subscribe{ _ in
            print("you`re out")
        }
        .addDisposableTo(disposeBag)
    //没反应
    strikes.onNext("X")
    strikes.onNext("X")
    strikes.onNext("X")
    //停止,则有输出
    strikes.onCompleted()
}

    //在一些时候我们想处理第N个元素, 这可以使用 `elementAt` 传递一个下标(从 0 开始),则次下标的元素可以通过
example(of: "elementAt") {
    let strikes = PublishSubject<String>()
    let disposeBag = DisposeBag()
    strikes.elementAt(2).subscribe(onNext:{_ in
        print("you`re out")
    }).addDisposableTo(disposeBag)
    //没反应
    strikes.onNext("X")
    strikes.onNext("X")
    //第三个 有反应
    strikes.onNext("X")

}

    //使用 `.fliter` 可以传递一个判断闭包, 元素当满足闭包内的判断时通过
example(of: "fliter") {
    let disposeBag = DisposeBag()
    //偶数可通过
//    Observable.of(1,2,3,4,5,6,7)
//        .filter{$0 % 2 == 0}
//        .subscribe(onNext:{
//            print($0)
//        })
//        .addDisposableTo(disposeBag)
    let strikes = PublishSubject<Int>()
//    let disposeBag = DisposeBag()
    strikes.filter({$0 % 2 == 0}).subscribe(onNext:{
        print($0)
    }).addDisposableTo(disposeBag)
    strikes.onNext(1)
    strikes.onNext(2)
    strikes.onNext(3)
}

//skipping operators
    //有时需要跳过一些的元素, 比如 天气预报. 你可能不想受到在此时间之前的事件. 使用 `skip` 操作符 传递一个 int值
    //可以跳过 第一个 至 第N(所传的值)个元素
example(of: "skip") {
    let disposeBag = DisposeBag()
    //跳过第一个 至 第三个
    Observable.of("A", "B", "C", "D", "E", "F").skip(3).subscribe(onNext:{
        print($0)
    }).addDisposableTo(disposeBag)
    
}

//`skipWhile` 跳过符合条件的 元素. 但在跳过该元素之后 `skipWhile`就失效了(让所有元素通过)
example(of: "skipWhile") {
    let disposeBag = DisposeBag()
    Observable.of(2, 2, 3, 4, 4)
        .skipWhile({
            //偶数跳过
            $0 % 2 == 0
        })
        .subscribe(onNext:{
            print($0)
        })
        .addDisposableTo(disposeBag)
}

    //动态控制跳过
    //使用 `skipUntil` 来跳过元素直到与之关联的 trigger observable 发出(next)事件.
example(of: "skipUntil") {
    let disposeBag = DisposeBag()
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    subject.skipUntil(trigger).subscribe(onNext:{
        print($0)
    }).addDisposableTo(disposeBag)
    subject.onNext("A")
    subject.onNext("B")
    trigger.onNext("X")
//    trigger.onCompleted()
//    trigger.onError(NSError())
    
    subject.onNext("C")
}

// `take`操作符 与 `skip` 相对 他可以只取得 第一个至 第N个元素
example(of: "take") {
    //取得 前三个元素
    let disposeBag = DisposeBag()
    Observable.of(1, 2, 3, 4, 5, 6).take(3).subscribe(onNext:{
        print($0)
    })
    .addDisposableTo(disposeBag)
    
}

// `takeWhileWithIndex` 携带一个闭包, 闭包有两个参数value(元素值) index(位置) 当满足闭包给的条件时就取值(总感觉类似.fliter)
example(of: "takeWhileWithIndex") {
    let disposeBag = DisposeBag()
    Observable.of(2, 2, 4, 4, 6, 6).takeWhileWithIndex({integer, index in
        integer % 2 == 0 && index < 3
    }).subscribe(onNext:{
        print($0)
    })
    .addDisposableTo(disposeBag)
}

//`takeUntil` 在trigger 触发之前 接收数据

example(of: "takeUntil") {
    let disposBag = DisposeBag()
    let subject = PublishSubject<String>()
    let trigger = PublishSubject<String>()
    subject.takeUntil(trigger).subscribe(onNext:{
        print($0)
    }).addDisposableTo(disposBag)
    subject.onNext("1")
    subject.onNext("2")
    //在此之后不会接收元素
    trigger.onNext("X")
    subject.onNext("3")
}

// Distinct operators 过滤相邻的相同元素
example(of: "distinctUntilChanged") {
    let disposeBag = DisposeBag()
    //string 服从于Equatable协议 因此其不指定比较方式则默认用此
    Observable.of("A","A","B","B","A")
        .distinctUntilChanged()
        .subscribe(onNext:{
            print($0)
        })
        .addDisposableTo(disposeBag)
    //自定比较规则 返回true代表相同(不输出),(ABC   若AB相同则保留最初(A),在下一个Next事件时比较 A和C)
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    Observable<NSNumber>.of(10, 110, 20, 200, 210, 310)
        .distinctUntilChanged({ (a, b) in
            guard let aWords = formatter.string(from: a)?.components(separatedBy: " "), let bWords = formatter.string(from: b)?.components(separatedBy: " ") else {
                return false
            }
            print(aWords,bWords )
            var containsMatch = false
            for aWord in aWords {
                for bWord in bWords {
                    if aWord == bWord {
                        containsMatch = true
                        break
                    }
                }
            }
            return containsMatch
        }).subscribe(onNext:{
            print($0)
        }).addDisposableTo(disposeBag)
    
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

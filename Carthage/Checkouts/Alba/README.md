# Alba

**Alba** is a tiny yet powerful library which allows you to create sophisticated, decoupled and complex architecture using functional-reactive paradigms. **Alba** is designed to work mostly with reference semantics instances (classes).

## Usage

#### Create publisher

```swift
let publisher = Publisher<UUID>()
publisher.publish(UUID())
```

#### Subscribing

In order to subscribe, you should use `Subscribe` instances. The easiest way to get them is by using `.proxy` property on publishers:

```swift
final class NumbersPrinter {
    
    init(numbersPublisher: Subscribe<Int>) {
        numbersPublisher.subscribe(self, with: NumbersPrinter.print)
    }
    
    func print(_ uuid: Int) {
        print(uuid)
    }
    
}

let printer = NumbersPrinter(numbersPublisher: publisher.proxy)
publisher.publish(10) // prints "10"
```

If you're surprised by how `NumbersPrinter.print` looks - that's because this allows **Alba** to do some interesting stuff with reference cycles. Check out the [implementation](https://github.com/dreymonde/Alba/blob/master/Sources/Proxy.swift#L52) for details.

#### That functional things

The cool thing about publisher proxies is the ability to do interesting things on them, for example, filter and map:

```swift
let stringPublisher = Publisher<String>()

final class Listener {
    
    init(publisher: Subscribe<String>) {
        publisher
            .flatMap({ Int($0) })
            .filter({ $0 > 0 })
            .subscribe(self, with: Listener.didReceive)
    }
    
    func didReceive(positiveNumber: Int) {
        print(positiveNumber)
    }
    
}

let listener = Listener(publisher: stringPublisher.proxy)
stringPublisher.publish("14aq") // nothing
stringPublisher.publish("-5")   // nothing
stringPublisher.publish("15")   // prints "15"
```

Cool, huh?

#### Lightweight observing

```swift
let publisher = Publisher<Int>()
publisher.proxy.listen { (number) in
    print(number)
}
publisher.publish(112) // prints "112"
```

Be careful with `listen`. Don't prefer it over `subscribe` as it can introduce memory leaks to your application.

### Observables

`Observable` is just a simple wrapper around a value with an embedded publisher. You can observe its changes using publicly available `proxy`:

```swift
final class State {
    var number: Observable<Int> = Observable(5)
    var isActive = Observable(false)    
}

let state = State()
state.number.proxy.subscribe( ... )
```

### Writing your own `Subscribe` extensions

If you want to write your own `Subscribe` extensions, you should use `rawModify` method:

```swift
public func rawModify<OtherEvent>(subscribe: (ObjectIdentifier, EventHandler<OtherEvent>) -> (), entry: @autoclosure @escaping ProxyPayload.Entry) -> Subscribe<OtherEvent>
```

Here is, for example, how you can implement `map`:

```swift
public extension Subscribe {
    
    public func map<OtherEvent>(_ transform: @escaping (Event) -> OtherEvent) -> Subscribe<OtherEvent> {
        return rawModify(subscribe: { (identifier, handle) in
            let handler: EventHandler<Event> = { event in
                handle(transform(event))
            }
            self._subscribe(identifier, handler)
        }, entry: .transformation(label: "mapped", .transformed(fromType: Event.self, toType: OtherEvent.self)))
    }
    
}
```

`entry` here is purely for debugging purposes -- you're describing the intention of your method.

### Inform Bureau

One of the main drawbacks of the functional-reactive style is an elevated level of indirection -- you can't easily detect the information flow in your application. **Alba** aims to solve this problem with the help of a handy feature called *Inform Bureau*. Inform Bureau collects information about every subscription and publishing inside your application, so it's easy for you to detect what's actually going on (and to detect any problems easily, of course).

#### Enabling Inform Bureau

Inform Bureau is an optional feature, so it should be enabled in your code in order to work. It's actually just one line of code -- make sure to put this in your `AppDelegate`'s `init` (`application(_:didFinishLaunchingWithOptions)` is too late):

```swift
Alba.InformBureau.isEnabled = true
```

Just this line will no have any immediate effect -- in order for Inform Bureau to become useful, you should also enable it's `Logger`:

```swift
Alba.InformBureau.Logger.enable()
```

And that's it! Now you're going to see beautiful messages like these in your output:

```
(S) ManagedObjectContextObserver.changes (Publisher<(NSChangeSet, Int)>)
(S) --> mapped from (NSChangeSet, Int) to NSSpecificChangeSet<CleaningPoint>
(S) !-> subscribed by PointsListViewController:4929411136
```

```
(S) +AppDelegate.applicationWillTerminate (Publisher<UIApplication>)
(S) --> mapped from UIApplication to ()
(S) merged with:
(S)    +AppDelegate.applicationDidEnterBackground (Publisher<UIApplication>)
(S)    --> mapped from UIApplication to ()
(S) !-> subscribed by ContextSaver:6176536960
```

```
(P) ContextSaver.didSaveContext (Publisher<()>) published ()
```

*Hint*: `(S)` are subscriptions events, and `(P)` are publications.

#### Getting your code ready for Inform Bureau

Inform Bureau can be enabled with two lines of code. However, in order for it to be useful, there is a little amount of work required from you. First and foremost, you should create all your publishers with descriptive `label`:

```swift
let didFailToSaveImage = Publisher<Error>(label: "ImageSaver.didFailToSaveImage")
```

You should name your publishers using the next convention: `[type_name].[publisher_name]`

If your publisher is declared as `static`, then add `+` to the beginning:

```swift
static let applicationWillTerminate = Publisher<UIApplication>(label: "+AppDelegate.applicationWillTerminate")
```

#### OSLogger

**Alba**'s Inform Bureau takes full advantage of Apple's latest [Unified Logging][unified-logging-wwdc] system. The support for this system comes via `Alba.OSLogger` object. If you want your app to write **Alba** logs via `os_log`, enable it after enabling `InformBureau`:

```swift
Alba.InformBureau.isEnabled = true
Alba.OSLogger.enable()
```

In order for `os_log` to work, you should also do [this](http://stackoverflow.com/a/40744462/5569590).

Now you can see **Alba** logs of your program in a **Console** application.

## Installation

**Alba** is available through [Carthage][carthage-url]. To install, just write into your Cartfile:

```ruby
github "dreymonde/Alba" ~> 0.3.3
```

You can also use SwiftPM. Just add to your `Package.swift`:

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/dreymonde/Alba.git", majorVersion: 0, minor: 3),
    ]
)
```

## Contributing

**Alba** is in early stage of development and is opened for any ideas. If you want to contribute, you can:

- Propose idea/bugfix in issues
- Make a pull request
- Review any other pull request (very appreciated!), since no change to this project is made without a PR.

Actually, any help is welcomed! Feel free to contact us, ask questions and propose new ideas. If you don't want to raise a public issue, you can reach me at [dreymonde@me.com](mailto:dreymonde@me.com).

[carthage-url]: https://github.com/Carthage/Carthage
[unified-logging-wwdc]: https://developer.apple.com/videos/play/wwdc2016/721/

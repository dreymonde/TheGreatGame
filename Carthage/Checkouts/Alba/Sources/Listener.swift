/**
 *  Alba
 *
 *  Copyright (c) 2016 Oleg Dreyman. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

internal class BasicListener<Event> {
    
    internal let publisher: Subscribe<Event>
    internal let handler: EventHandler<Event>
    
    internal init(subscribingTo publisher: Subscribe<Event>,
                _ handler: @escaping EventHandler<Event>) {
        self.publisher = publisher
        self.handler = handler
        publisher.manual.subscribe(self, with: handler)
    }
    
    internal init<Pub : PublisherProtocol>(subscribingTo publisher: Pub,
                _ handler: @escaping EventHandler<Event>) where Pub.Event == Event {
        self.publisher = publisher.proxy
        self.handler = handler
        self.publisher.manual.subscribe(self, with: handler)
    }
    
    deinit {
        publisher.manual.unsubscribe(self)
    }
    
}

internal class NotGoingBasicListener<Event> {
    
    let publisher: Subscribe<Event>
    let handler: EventHandler<Event>
    
    init(subscribingTo publisher: Subscribe<Event>,
         _ handler: @escaping EventHandler<Event>) {
        self.publisher = publisher
        self.handler = handler
        publisher.manual.subscribe(self, with: self.handle)
    }
    
    init<Pub : PublisherProtocol>(subscribingTo publisher: Pub,
         _ handler: @escaping EventHandler<Event>) where Pub.Event == Event {
        self.publisher = publisher.proxy
        self.handler = handler
        self.publisher.manual.subscribe(self, with: self.handle)
    }
    
    func handle(_ event: Event) {
        self.handler(event)
    }
    
    deinit {
        publisher.manual.unsubscribe(self)
    }
    
}

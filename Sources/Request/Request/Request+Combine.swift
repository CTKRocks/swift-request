//
//  Request+Combine.swift
//  
//
//  Created by Carson Katri on 7/27/20.
//

import Foundation
import Combine
import Json

extension AnyRequest: Publisher {
    public typealias Output = URLSession.DataTaskPublisher.Output
    public typealias Failure = Error
    
    public func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Failure, S.Input == Output {
        updatePublisher?
            .receive(subscriber: UpdateSubscriber(request: self))
        buildPublisher()
            .subscribe(subscriber)
    }
    
    public typealias DataMapPublisher = Publishers.MapKeyPath<AnyRequest<ResponseType>, JSONDecoder.Input>
    public typealias ObjectPublisher = Publishers.Decode<DataMapPublisher, ResponseType, JSONDecoder>
    public var objectPublisher: ObjectPublisher {
        map(\.data)
            .decode(type: ResponseType.self, decoder: JSONDecoder())
    }
    
    public typealias StringPublisher = Publishers.CompactMap<AnyRequest<ResponseType>, String>
    public var stringPublisher: StringPublisher {
        compactMap {
            String(data: $0.data, encoding: .utf8)
        }
    }
    
    public typealias JsonPublisher = Publishers.TryMap<StringPublisher, Json>
    public var jsonPublisher: JsonPublisher {
        stringPublisher
            .tryMap {
                try Json($0)
            }
    }
    
    public typealias UpdatePublisher<Downstream, Upstream> = Publishers.FlatMap<Downstream, Upstream>
    where Downstream: Publisher, Upstream: Publisher, Downstream.Failure == Error, Upstream.Failure == Error
    
    func updatePublisher<T: Publisher>(publisher: T) -> UpdatePublisher<Self, T> {
        publisher.flatMap { _ in self }
    }
    
    public typealias UpdateTimerPublisher = UpdatePublisher<Self, Publishers.MapError<Publishers.Autoconnect<Timer.TimerPublisher>, Error>>
    
    func updatePublisher(every seconds: TimeInterval) -> UpdateTimerPublisher {
        updatePublisher(publisher: Timer.publish(every: seconds, on: .main, in: .common)
                            .autoconnect()
                            .mapError { _ in RequestError(statusCode: -1, error: nil) })
    }
}

extension AnyRequest: Subscriber {
    public typealias Input = (data: Data, response: URLResponse)
    
    public func receive(subscription: Subscription) {
        subscription.request(.max(1))
    }
    
    public func receive(_ input: Input) -> Subscribers.Demand {
        if let res = input.response as? HTTPURLResponse {
            let statusCode = res.statusCode

            if let onStatusCode = self.onStatusCode {
                onStatusCode(statusCode)
            }

            if statusCode < 200 || statusCode >= 300 {
                if let onError = self.onError {
                    onError(RequestError(statusCode: statusCode, error: input.data))
                    return .none
                }
            }
        }
        if let onData = self.onData {
            onData(input.data)
        }
        if let onString = self.onString {
            if let string = String(data: input.data, encoding: .utf8) {
                onString(string)
            }
        }
        if let onJson = self.onJson {
            if let string = String(data: input.data, encoding: .utf8) {
                if let json = try? Json(string) {
                    onJson(json)
                }
            }
        }
        if let onObject = self.onObject {
            if let decoded = try? JSONDecoder().decode(ResponseType.self, from: input.data) {
                onObject(decoded)
            }
        }
        return .none
    }
    
    public func receive(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure(let err): onError?(err)
        case .finished: return
        }
    }
}

extension AnyRequest {
    struct UpdateSubscriber: Subscriber {
        let combineIdentifier: CombineIdentifier = CombineIdentifier()
        let request: AnyRequest<ResponseType>
        
        typealias Input = Void
        typealias Failure = Never
        
        func receive(subscription: Subscription) {
            subscription.request(.unlimited)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            request.call()
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            return
        }
    }
}

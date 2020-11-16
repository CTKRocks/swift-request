//
//  File.swift
//  
//
//  Created by Carson Katri on 6/23/20.
//

import Foundation

/// Sets the `timeoutIntervalForRequest` and/or `timeoutIntervalForResource` of the `Request`
public struct Timeout: RequestParam, SessionConfiguration {
    private let timeout: TimeInterval
    private let source: Source
    
    public init(_ timeout: TimeInterval, for source: Source = .all) {
        self.timeout = timeout
        self.source = source
    }

    func buildConfiguration(_ sessionConfiguration: URLSessionConfiguration) {
        if source.contains(.request) {
            sessionConfiguration.timeoutIntervalForRequest = timeout
        }

        if source.contains(.resource) {
            sessionConfiguration.timeoutIntervalForResource = timeout
        }
    }
}

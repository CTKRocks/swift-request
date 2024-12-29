//
//  File.swift
//  
//
//  Created by brennobemoura on 15/11/20.
//

import Foundation

public struct CombinedParams: RequestParam, SessionParam {
    public let children: [RequestParam]

    init(children: [RequestParam]) {
        self.children = children
    }

    public func buildParam(_ request: inout URLRequest) {
        children
            .sorted { a, _ in (a is Url) }
            .filter { !($0 is SessionParam) || $0 is CombinedParams }
            .forEach {
                $0.buildParam(&request)
            }
    }

    public func buildConfiguration(_ configuration: URLSessionConfiguration) {
        children
            .compactMap { $0 as? SessionParam }
            .forEach {
                $0.buildConfiguration(configuration)
            }
    }
}

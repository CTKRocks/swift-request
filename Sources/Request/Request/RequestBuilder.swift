//
//  File.swift
//  
//
//  Created by Carson Katri on 6/30/19.
//

import Foundation

@_functionBuilder
public struct RequestBuilder {
    public static func buildBlock(_ params: RequestParam...) -> RequestParam {
        CombinedParams(children: params)
    }

    public static func buildBlock(_ param: RequestParam) -> RequestParam {
        param
    }

    public static func buildIf(_ param: RequestParam?) -> RequestParam {
        param ?? EmptyParam()
    }

    public static func buildEither(first: RequestParam) -> RequestParam {
        first
    }

    public static func buildEither(second: RequestParam) -> RequestParam {
        second
    }
}

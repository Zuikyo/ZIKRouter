//
//  SwiftStruct.swift
//  ZIKRouterDemo
//
//  Created by zuik on 2017/11/23.
//  Copyright © 2017 zuik. All rights reserved.
//

enum SwiftStructType {
    case one
    case two
}

protocol SwiftStructInput {
    func swiftFunction()
}

public struct SwiftStruct: SwiftStructInput {
    func swiftFunction() {
        print(self)
    }
}

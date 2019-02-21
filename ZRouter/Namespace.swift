//
//  Namespace.swift
//  ZRouter
//
//  Created by zuik on 2017/10/24.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation

public protocol NamespaceWrappable: class {
    associatedtype WrapperType
    var zix: WrapperType { get }
    static var zix: WrapperType.Type { get }
}

public extension NamespaceWrappable {
    var zix: NamespaceWrapper<Self> {
        get {
            return NamespaceWrapper(value: self)
        }
        set { }
    }
    
    static var zix: NamespaceWrapper<Self>.Type {
        get {
            return NamespaceWrapper.self
        }
        set { }
    }
}

public protocol TypeWrapperProtocol {
    associatedtype WrappedType
    var wrappedValue: WrappedType { get }
    init(value: WrappedType)
}

public struct NamespaceWrapper<T>: TypeWrapperProtocol {
    public let wrappedValue: T
    public init(value: T) {
        self.wrappedValue = value
    }
}

//
//  ViewExtension.swift
//  ZRouter
//
//  Created by zuik on 2017/10/23.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import ZIKRouter

#if os(iOS) || os(watchOS) || os(tvOS)
public typealias ViewController = UIViewController
public typealias View = UIView
#elseif os(OSX)
public typealias ViewController = NSViewController
public typealias View = NSView
#else
#endif

extension ViewController: NamespaceWrappable { }
public extension TypeWrapperProtocol where WrappedType: ViewController {
    
    /// See zix_routed
    public var routed: Bool {
        return wrappedValue.zix_routed
    }
    
    /// See zix_removing
    public var removing: Bool {
        return wrappedValue.zix_removing
    }
}

extension View: NamespaceWrappable { }
public extension TypeWrapperProtocol where WrappedType: View {
    
    /// See zix_routed
    public var routed: Bool {
        return wrappedValue.zix_routed
    }
}

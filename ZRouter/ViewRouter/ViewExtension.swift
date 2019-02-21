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
    
    /// If the ViewController is already routed, return true, otherwise return false.
    ///
    /// Check ViewController is routed or not, then determine a ViewController is first appear or is removing. This property is for all ViewController.  The implementation is in ZIKViewRouter.
    ///
    /// If a ViewController is first appear, routed will be false in viewWillAppear(_:) and viewDidAppear(_:) (before super.viewDidAppear(_:), it's true after super.viewDidAppear(_:)). If a ViewController is removing, routed will be false in viewDidDisappear(_:). When a ViewController is displaying (even invisible), that means it's routed, routed is true.
    var routed: Bool {
        return wrappedValue.zix_routed
    }
    
    /// If the ViewController is removing, return true, otherwise return false.
    ///
    /// Check ViewController is removing or not. This property is for all ViewController. The implementation is in ZIKViewRouter.
    ///
    /// If a ViewController is removing, removing will be true in viewWillDisappear(_:) and viewDidDisappear(_:) (before super.viewDidDisappear(_:), it's false after super.viewDidDisappear(_:)). A removing may be cancelled, such as user swipes to pop view controller from navigation stack but the swiping gesture is cancelled.
    var removing: Bool {
        return wrappedValue.zix_removing
    }
    
}

extension View: NamespaceWrappable { }
public extension TypeWrapperProtocol where WrappedType: View {
    
    /// If the View is already routed, return true, otherwise return false.
    ///
    /// Check View is routed or not, then determine a View is first appear or is removing from superview. Routed means the View is added to a superview and appeared once. This property is for all View. The implementation is in ZIKViewRouter.
    ///
    /// If a View is adding to superview, willMove(toSuperview: newSuperview) will be called, newSuperview is not nil. If a View is removing from superview, willMove(toSuperview: nil) will be called.
    ///
    /// If view is first appear, routed will be false in willMove(toSuperview:), didMoveToSuperview, willMove(toWindow:), didMoveToWindow (before super.didMoveToWindow, it's true after super.didMoveToWindow). If view is removing from superview, routed will be false in willMove(toSuperview:) and -didMoveToSuperview, but it's still true in willMove(toWindow:) and didMoveToWindow. When a View has appeared once, that means it's routed, routed is true.
    var routed: Bool {
        return wrappedValue.zix_routed
    }
    
    /// Whether the View is removing. true in -willMoveToSuperview:nil and -didMoveToWindow nil.
    var removing: Bool {
        return wrappedValue.zix_removing
    }
    
}

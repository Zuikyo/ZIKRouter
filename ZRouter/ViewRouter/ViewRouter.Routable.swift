//
//  Routable.swift
//  ZRouter
//
//  Created by zuik on 2017/11/6.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import ZIKRouter

/**
 Entry for routable view protocol, only available for explicitly declared protocol.
 
 Declare that protocol `TestViewInput` is routable as a view protocol:
 ```
 extension RoutableView where Protocol == TestViewInput {
     init() { self.init(declaredProtocol: Protocol.self) }
 }
 ```
 Now we can access to the initializer method when the generic parameter `Protocol` is `TestViewInput`, and use `TestViewInput` in router:
 ```
 Router.perform(
 to: RoutableView<TestViewInput>(),
 path: .presentModally(from: self),
 configuring: { (config, _) in
     config.prepareDestination = { destination in
        //destination is inferred as TestViewInput
     }
 })
 ```
 The Protocol can also be composed type, like:
 ```
 UIViewController & TestViewInput
 ```
 or
 ```
 TestViewInput & AnotherViewInput
 ```
 When a type is declared as routable, you should register it in router's `registerRoutableDestiantion()`. In DEBUG mode, ZRouter will enumerate all declared type and make sure they are all registered.
 - Warning
 Never add extension for RoutableView without generic constraint and expose its initializer.
 - Note
 When there is only one declared protocol, swift compiler will use that protocol as default generic parameter.
 */
public struct RoutableView<Protocol> {
    
    /// Name of the routable type, equal to `String(describing: Protocol.self)`.
    let typeName: String
    
    @available(*, unavailable, message: "Protocol is not declared as routable")
    public init() { typeName = String(describing: Protocol.self) }
    
    /// Only use this in initializers in extension, never use it in other place. This is only to silence the warning of `initializer for struct 'xxx' must use "self.init(...)" or "self = ..." because it is not in module xxx`. See https://github.com/apple/swift-evolution/blob/master/proposals/0189-restrict-cross-module-struct-initializers.md
    ///
    /// - Parameter declaredProtocol: The protocol must be declared in extension.
    public init(declaredProtocol: Protocol.Type) { typeName = String(describing: Protocol.self) }
    
    /// Only use this in initializers in extension, never use it in other place. This function provides much higher performance. When registering more than 500 routable modules, it will cost more than 100 ms, because `String(describing:)` has poor performance. This initializer can avoid using `String(describing:)`, and gives us a factor of 10 improvement in performance.
    ///
    /// - Parameter declaredTypeName: The name of declared protocol in extension. Must be equal to the name from `String(describing: Protocol.self)`, or there will be assert failure.
    public init(declaredTypeName: String) {
        assert(declaredTypeName == String(describing: Protocol.self), "declaredTypeName should equal to String(describing:) of \(Protocol.self)")
        typeName = declaredTypeName
    }
}

/**
 Entry for routable view module protocol, only available for explicitly declared protocol.
 
 Declare that protocol `TestViewModuleInput` is routable as a view module protocol:
 ```
 extension RoutableViewModule where Protocol == TestViewModuleInput {
     init() { self.init(declaredProtocol: Protocol.self) }
 }
 ```
 The Protocol can also be composed type, like:
 ```
 TestViewModuleInput & AnotherViewModuleInput
 ```
  When a type is declared as routable, you should register it in router's `registerRoutableDestiantion()`. In DEBUG mode, ZRouter will enumerate all declared type and make sure they are all registered.
 - Warning
 Never add extension for RoutableViewModule without generic constraint and expose its initializer.
 */
public struct RoutableViewModule<Protocol> {
    
    /// Name of the routable type, equal to `String(describing: Protocol.self)`.
    let typeName: String
    
    @available(*, unavailable, message: "Protocol is not declared as routable")
    public init() { typeName = String(describing: Protocol.self) }
    
    /// Only use this in initializers in extension, never use it in other place. This is only to silence the warning of `initializer for struct 'xxx' must use "self.init(...)" or "self = ..." because it is not in module xxx`. See https://github.com/apple/swift-evolution/blob/master/proposals/0189-restrict-cross-module-struct-initializers.md
    ///
    /// - Parameter declaredProtocol: The protocol must be declared in extension.
    public init(declaredProtocol: Protocol.Type) { typeName = String(describing: Protocol.self) }
    
    /// Only use this in initializers in extension, never use it in other place. This function provides much higher performance. When registering more than 500 routable modules, it will cost more than 100 ms, because `String(describing:)` has poor performance. This initializer can avoid using `String(describing:)`, and gives use a factor of 10 improvement in performance.
    ///
    /// - Parameter declaredTypeName: The name of declared protocol in extension. Must be equal to the name from `String(describing: Protocol.self)`, or there will be assert failure.
    public init(declaredTypeName: String) {
        assert(declaredTypeName == String(describing: Protocol.self), "declaredTypeName should equal to String(describing:) of \(Protocol.self)")
        typeName = declaredTypeName
    }
}

/// All protocols inheriting from ZIKViewRoutable are routable as view protocol. You may find out the compiler also allows using class type that conforming to ZIKViewRoutable as `Protocol`. ZRouter can detect them and give assert failure.
public extension RoutableView where Protocol: ZIKViewRoutable {
    init() {
        if let objcProtocol = zix_objcProtocol(Protocol.self) {
            typeName = objcProtocol.name
        } else {
            typeName = String(describing: Protocol.self)
            assertionFailure("Generic parameter \(Protocol.self) should be protocol type.")
        }
    }
}

/// All protocols inheriting from ZIKViewModuleRoutable are routable as view module protocol. You may find out the compiler also allows using class type that conforming to ZIKViewModuleRoutable as `Protocol`. ZRouter can detect them and give assert failure.
public extension RoutableViewModule where Protocol: ZIKViewModuleRoutable {
    init() {
        if let objcProtocol = zix_objcProtocol(Protocol.self) {
            typeName = objcProtocol.name
        } else {
            typeName = String(describing: Protocol.self)
            assertionFailure("Generic parameter \(Protocol.self) should be protocol type.")
        }
    }
}

#if DEBUG

// MARK: Invalid Check

/// When using ZRouter as dynamic framework, these symbols should never be linked in your code, if linked, that means you are using some undeclared type as generic parameter of RoutableView / RoutableViewModule.

/* Invalid usage of RoutableView. Don't use an UIViewController as generic parameter of RoutableView:
 ```
 @objc protocol SomeViewProtocol: ZIKViewRoutable {
 
 }
 // There is a view controller conforms to ZIKViewRoutable
 class SomeViewController: UIViewController, SomeViewProtocol {
 
 }
 ```
 ```
 // Invalid usage, can't get router with it
 RoutableView<SomeViewController>()
 ```
 You should use the protocol to get its router, although the compiler won't give error when `SomeViewController` is used as generic parameter of RoutableView. These invalid usages will be detected when registration is finished.
 
 If it's hard to find out the bad code, you can use `Hopper Disassembler` to analyze your app and see references to this symbol:
 (extension in ZRouter):ZRouter.RoutableView<A where A: __ObjC.UIViewController, A: __ObjC.ZIKViewRoutable>.init() -> ZRouter.RoutableView<A>
 */
public extension RoutableView where Protocol: ZIKViewRoutable, Protocol: ViewController {
    init() {
        typeName = String(describing: Protocol.self)
        assertionFailure("Generic parameter \(Protocol.self) should be protocol type.")
    }
}

public extension RoutableView where Protocol: ZIKViewRoutable, Protocol: View {
    init() {
        typeName = String(describing: Protocol.self)
        assertionFailure("Generic parameter \(Protocol.self) should be protocol type.")
    }
}

/// Invalid usage: RoutableView<ZIKViewRoutable>()
public extension RoutableView where Protocol == ZIKViewRoutable {
    init() {
        typeName = String(describing: Protocol.self)
        assertionFailure("Don't use ZIKViewRoutable as generic parameter, can't get any router.")
    }
}

/* Invalid usage of RoutableViewModule. Don't use a ZIKViewRouteConfiguration as generic parameter of RoutableViewModule:
 ```
 @objc protocol SomeViewModuleProtocol: ZIKViewModuleRoutable {
 
 }
 // There is a custom view configuration conforms to ZIKViewModuleRoutable
 class SomeViewRouteConfiguration: ZIKViewRouteConfiguration, SomeViewModuleProtocol {
 
 }
 ```
 ```
 // Invalid usage, can't get router with it
 RoutableViewModule<SomeViewRouteConfiguration>()
 ```
 You should use the protocol to get its router, although the compiler won't give error when `SomeViewRouteConfiguration` is used as generic parameter of RoutableViewModule. These invalid usages will be detected when registration is finished.
 
 If it's hard to find out the bad code, you can use `Hopper Disassembler` to analyze your app and see references to this symbol:
 (extension in ZRouter):ZRouter.RoutableViewModule<A where A: __ObjC.ZIKViewRouteConfiguration, A: __ObjC.ZIKViewModuleRoutable>.init() -> ZRouter.RoutableViewModule<A>
 */
public extension RoutableViewModule where Protocol: ZIKViewModuleRoutable, Protocol: ZIKViewRouteConfiguration {
    init() {
        typeName = String(describing: Protocol.self)
        assertionFailure("Generic parameter \(Protocol.self) should be protocol type.")
    }
}

/// Invalid usage: RoutableViewModule<ZIKViewModuleRoutable>()
public extension RoutableViewModule where Protocol == ZIKViewModuleRoutable {
    init() {
        typeName = String(describing: Protocol.self)
        assertionFailure("Don't use ZIKViewModuleRoutable as generic parameter, can't get any router.")
    }
}

#endif

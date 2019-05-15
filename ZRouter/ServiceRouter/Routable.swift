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
 Entry for routable service protocol, only available for explicitly declared protocol.
 
 Declare that protocol `TestServiceInput` is routable as a service protocol:
 ```
 extension RoutableService where Protocol == TestServiceInput {
     init() { self.init(declaredProtocol: Protocol.self) }
 }
 ```
 The Protocol can also be composed type, like:
 ```
 ServiceType & TestServiceInput
 ```
 or
 ```
 TestServiceInput & AnotherServiceInput
 ```
  When a type is declared as routable, you should register it in router's `registerRoutableDestiantion()`. In DEBUG mode, ZRouter will enumerate all declared type and make sure they are all registered.
 - Warning
 Never add extension for RoutableServiceModule without generic constraint and expose its initializer.
 */
public struct RoutableService<Protocol> {
    
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

/**
 Entry for routable service module protocol, only available for explicitly declared protocol.
 
 Declare that protocol `TestServiceInput` is routable as a service protocol:
 ```
 extension RoutableServiceModule where Protocol == TestServiceModuleInput {
     init() { self.init(declaredProtocol: Protocol.self) }
 }
 ```
  When a type is declared as routable, you should register it in router's `registerRoutableDestiantion()`. In DEBUG mode, ZRouter will enumerate all declared type and make sure they are all registered.
 - Warning
 Never add extension for RoutableServiceModule without generic constraint and expose its initializer.
 */
public struct RoutableServiceModule<Protocol> {
    
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

/// All protocols inheriting from ZIKServiceRoutable are routable as service protocol. You may find out the compiler also allows using class type that conforming to ZIKServiceRoutable as `Protocol`. ZRouter can detect them and give assert failure.
public extension RoutableService where Protocol: ZIKServiceRoutable {
    init() {
        if let objcProtocol = zix_objcProtocol(Protocol.self) {
            typeName = objcProtocol.name
        } else {
            typeName = String(describing: Protocol.self)
            assertionFailure("Generic parameter \(Protocol.self) should be protocol type.")
        }
    }
}

/// All protocols inheriting from ZIKServiceRoutable are routable as service module protocol. You may find out the compiler also allows using class type that conforming to ZIKServiceModuleRoutable as `Protocol`. ZRouter can detect them and give assert failure.
public extension RoutableServiceModule where Protocol: ZIKServiceModuleRoutable {
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

/// When using ZRouter as dynamic framework, these symbols should never be linked in your code, if linked, that means you are using some undeclared type as generic parameter of RoutableService / RoutableServiceModule.

/* Invalid usage of RoutableService. Don't use an object type as generic parameter of RoutableService:
 ```
 @objc protocol SomeServiceProtocol: ZIKServiceRoutable {
 
 }
 // There is a class conforms to ZIKServiceRoutable
 class SomeClassType: NSObject, SomeServiceProtocol {
 
 }
 ```
 ```
 // Invalid usage, can't get router with it
 RoutableService<SomeClassType>()
 ```
 You should use the protocol to get its router, although the compiler won't give error when `SomeClassType` is used as generic parameter of RoutableService. These invalid usages will be detected when registration is finished.
 
 If it's hard to find out the bad code, you can use `Hopper Disassembler` to analyze your app and see references to this symbol:
 (extension in ZRouter):ZRouter.RoutableService<A where A: __ObjC.NSObject, A: __ObjC.ZIKServiceRoutable>.init() -> ZRouter.RoutableService<A>
 */
public extension RoutableService where Protocol: ZIKServiceRoutable, Protocol: NSObject {
    init() {
        typeName = String(describing: Protocol.self)
        assertionFailure("Generic parameter \(Protocol.self) should be protocol type.")
    }
}

/// Invalid usage: RoutableService<ZIKServiceRoutable>()
public extension RoutableService where Protocol == ZIKServiceRoutable {
    init() {
        typeName = String(describing: Protocol.self)
        assertionFailure("Don't use ZIKServiceRoutable as generic parameter, can't get any router.")
    }
}

/* Invalid usage of RoutableServiceModule. Don't use a ZIKPerformRouteConfiguration as generic parameter of RoutableServiceModule:
 ```
 @objc protocol SomeServiceModuleProtocol: ZIKServiceModuleRoutable {
 
 }
 // There is a custom configuration conforms to ZIKServiceModuleRoutable
 class SomeServiceRouteConfiguration: ZIKPERFORMRouteConfiguration, SomeServiceModuleProtocol {
 
 }
 ```
 ```
 // Invalid usage, can't get router with it
 RoutableServiceModule<SomeServiceRouteConfiguration>()
 ```
 You should use the protocol to get its router, although the compiler won't give error when `SomeServiceRouteConfiguration` is used as generic parameter of RoutableServiceModule. These invalid usages will be detected when registration is finished.
 
 If it's hard to find out the bad code, you can use `Hopper Disassembler` to analyze your app and see references to this symbol:
 (extension in ZRouter):ZRouter.RoutableServiceModule<A where A: __ObjC.ZIKPerformRouteConfiguration, A: __ObjC.ZIKServiceModuleRoutable>.init() -> ZRouter.RoutableServiceModule<A>
 */
public extension RoutableServiceModule where Protocol: ZIKServiceModuleRoutable, Protocol: ZIKPerformRouteConfiguration {
    init() {
        typeName = String(describing: Protocol.self)
        assertionFailure("Generic parameter \(Protocol.self) should be protocol type.")
    }
}

/// Invalid usage: RoutableServiceModule<ZIKServiceModuleRoutable>()
public extension RoutableServiceModule where Protocol == ZIKServiceModuleRoutable {
    init() {
        typeName = String(describing: Protocol.self)
        assertionFailure("Don't use ZIKServiceModuleRoutable as generic parameter, can't get any router.")
    }
}

#endif

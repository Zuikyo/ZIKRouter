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
 from: self,
 configuring: { (config, prepareDestination, _) in
     config.routeType = .presentModally
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
 Never add extension for RoutableView without generic constraint and expose it's initializer.
 - Note
 When there is only one declared protocol, swift complier will use that protocol as default generic parameter.
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
    
    /// Only use this in initializers in extension, never use it in other place. This function provides much higher performence. When registering more than 500 routable modules, it will cost more than 100 ms, because `String(describing:)` has poor performance. This initializer can avoid using `String(describing:)`, and gives us a factor of 10 improvement in performance.
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
 Never add extension for RoutableViewModule without generic constraint and expose it's initializer.
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
    
    /// Only use this in initializers in extension, never use it in other place. This function provides much higher performence. When registering more than 500 routable modules, it will cost more than 100 ms, because `String(describing:)` has poor performance. This initializer can avoid using `String(describing:)`, and gives use a factor of 10 improvement in performance.
    ///
    /// - Parameter declaredTypeName: The name of declared protocol in extension. Must be equal to the name from `String(describing: Protocol.self)`, or there will be assert failure.
    public init(declaredTypeName: String) {
        assert(declaredTypeName == String(describing: Protocol.self), "declaredTypeName should equal to String(describing:) of \(Protocol.self)")
        typeName = declaredTypeName
    }
}

/**
 Entry for routable service protocol, only available for explicitly declared protocol.
 
 Declare that protocol `TestServiceInput` is routable as a service protocol:
 ```
 extension RoutableServiceModule where Protocol == TestServiceInput {
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
 Never add extension for RoutableServiceModule without generic constraint and expose it's initializer.
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
    
    /// Only use this in initializers in extension, never use it in other place. This function provides much higher performence. When registering more than 500 routable modules, it will cost more than 100 ms, because `String(describing:)` has poor performance. This initializer can avoid using `String(describing:)`, and gives use a factor of 10 improvement in performance.
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
 Never add extension for RoutableServiceModule without generic constraint and expose it's initializer.
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
    
    /// Only use this in initializers in extension, never use it in other place. This function provides much higher performence. When registering more than 500 routable modules, it will cost more than 100 ms, because `String(describing:)` has poor performance. This initializer can avoid using `String(describing:)`, and gives use a factor of 10 improvement in performance.
    ///
    /// - Parameter declaredTypeName: The name of declared protocol in extension. Must be equal to the name from `String(describing: Protocol.self)`, or there will be assert failure.
    public init(declaredTypeName: String) {
        assert(declaredTypeName == String(describing: Protocol.self), "declaredTypeName should equal to String(describing:) of \(Protocol.self)")
        typeName = declaredTypeName
    }
}

///All protocols inherited from ZIKViewRoutable are routable as view protocol.
public extension RoutableView where Protocol: ZIKViewRoutable {
    init() {
        if let objcProtocol = ZIKRouter_objcProtocol(Protocol.self) {
            typeName = objcProtocol.name
        } else {
            typeName = String(describing: Protocol.self)
            assert(false,"Generic parameter \(Protocol.self) should be protocol type.")
        }
    }
}

///All protocols inherited from ZIKViewModuleRoutable are routable as view module protocol.
public extension RoutableViewModule where Protocol: ZIKViewModuleRoutable {
    init() {
        if let objcProtocol = ZIKRouter_objcProtocol(Protocol.self) {
            typeName = objcProtocol.name
        } else {
            typeName = String(describing: Protocol.self)
            assert(false,"Generic parameter \(Protocol.self) should be protocol type.")
        }
    }
}

///All protocols inherited from ZIKServiceRoutable are routable as service protocol.
public extension RoutableService where Protocol: ZIKServiceRoutable {
    init() {
        if let objcProtocol = ZIKRouter_objcProtocol(Protocol.self) {
            typeName = objcProtocol.name
        } else {
            typeName = String(describing: Protocol.self)
            assert(false,"Generic parameter \(Protocol.self) should be protocol type.")
        }
    }
}

///All protocols inherited from ZIKViewRoutable are routable as service module protocol.
public extension RoutableServiceModule where Protocol: ZIKServiceModuleRoutable {
    init() {
        if let objcProtocol = ZIKRouter_objcProtocol(Protocol.self) {
            typeName = objcProtocol.name
        } else {
            typeName = String(describing: Protocol.self)
            assert(false,"Generic parameter \(Protocol.self) should be protocol type.")
        }
    }
}

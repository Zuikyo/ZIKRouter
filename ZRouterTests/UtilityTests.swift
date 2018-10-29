//
//  UtilityTests.swift
//  ZRouterTests
//
//  Created by zuik on 2018/5/11.
//  Copyright © 2018 zuik. All rights reserved.
//

import XCTest
import ZIKRouter.Private
import ZRouter

protocol SwiftClassProtocol { }
protocol SwiftClassSubProtocol: SwiftClassProtocol { }

@objc protocol ObjcClassProtocol { }
@objc protocol ObjcClassSubProtocol: ObjcClassProtocol { }

protocol ProtocolA { }
protocol ProtocolB { }
typealias ComposedProtocol = ProtocolA & ProtocolB


class SwiftClass: SwiftClassSubProtocol, ObjcClassSubProtocol, ComposedProtocol, Encodable {
    func encode(to encoder: Encoder) throws { }
}
class SwiftSubclass: SwiftClass { }
class UnusedSwiftClass { }

class GenericClass<T>: SwiftClassSubProtocol, ObjcClassSubProtocol, ComposedProtocol, Encodable {
    func encode(to encoder: Encoder) throws { }
}
class SubGenericClass: GenericClass<Any> { }
class GenericSubclass<T>: GenericClass<Any> { }
class UnusedGenericClass<T> { }

@objc class ObjcClass: NSObject, SwiftClassSubProtocol, ObjcClassSubProtocol, ComposedProtocol, Encodable {
    func encode(to encoder: Encoder) throws { }
}
@objc class ObjcSubclass: ObjcClass { }
@objc class UnusedObjcClass: NSObject { }

extension UIViewController: ComposedProtocol { }
extension ObjcViewController: SwiftClassSubProtocol, ObjcClassSubProtocol, Encodable {
    public func encode(to encoder: Encoder) throws { }
}
class GenericObjcViewController<T>: ObjcViewController { }
extension ObjcService: SwiftClassSubProtocol, ObjcClassSubProtocol, ComposedProtocol, Encodable {
    public func encode(to encoder: Encoder) throws { }
}
class GenericObjcClass<T>: ObjcService { }

protocol SwiftStructProtocol { }
protocol SwiftStructSubProtocol: SwiftStructProtocol { }

struct SwiftStruct: SwiftStructSubProtocol, ComposedProtocol, Encodable {
    func encode(to encoder: Encoder) throws { }
}
struct UnusedSwiftStruct { }

protocol SwiftEnumProtocol { }
protocol SwiftEnumSubProtocol: SwiftEnumProtocol { }

enum SwiftEnum: SwiftEnumSubProtocol, ComposedProtocol, Encodable {
    func encode(to encoder: Encoder) throws { }
    
    case case1
}
enum UnusedSwiftEnum { }

protocol UnusedSwiftProtocol { }
@objc protocol UnusedObjcProtocol { }

#if DEBUG

class UtilityTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        TestRouteRegistry.setUp()
    }
    
    func testTypeCheckingForSwiftClass() {
        // Swift class
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, SwiftClass.self))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.self, (Encodable & ProtocolA).self))
    }
    
    func testTypeCheckingForSwiftClassFailure() {
        // Check failing cases
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, SwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, NSCoding.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, Decodable.self))
    }
    
    func testTypeCheckingForSwiftSubclass() {
        // Swift subclass
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, SwiftClass.self))
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(SwiftSubclass.self, (Encodable & ProtocolA).self))
    }
    
    func testTypeCheckingForSwiftSubclassFailure() {
        // Check failing cases
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, SwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, NSCoding.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, Decodable.self))
    }
    
    func testTypeCheckingForSwiftClassWithGenericParameters() {
        // Swift class with generic parameters
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, GenericClass<Any>.self))
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(GenericClass<Any>.self, (Encodable & ProtocolA).self))
    }
    
    func testTypeCheckingForSwiftClassWithGenericParametersFailure() {
        // Check failing cases
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, SwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, NSCoding.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, Decodable.self))
    }
    
    func testTypeCheckingForSwiftSubclassForClassWithGenericParameters() {
        // Swift subclass for class with generic parameters
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, SubGenericClass.self))
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(SubGenericClass.self, (Encodable & ProtocolA).self))
    }
    
    func testTypeCheckingForSwiftSubclassForClassWithGenericParametersFailure() {
        // Check failing cases
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, SwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, NSCoding.self))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, Decodable.self))
    }
    
    func testTypeCheckingForSwiftSubclassWithGenericParameters() {
        // Swift subclass with generic parameters
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, GenericClass<Any>.self))
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(GenericSubclass<Any>.self, (Encodable & ProtocolA).self))
    }
    
    func testTypeCheckingForSwiftSubclassWithGenericParametersFailure() {
        // Check failing cases
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, SwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, NSCoding.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, Decodable.self))
    }
    
    func testTypeCheckingForObjcClass() {
        // Objc class
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, ObjcClass.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClass.self, (Encodable & ProtocolA).self))
    }
    
    func testTypeCheckingForObjcClassFailure() {
        // Check failing cases
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, UnusedObjcClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, SwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, NSCoding.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, Decodable.self))
    }
    
    func testTypeCheckingForObjcSubclass() {
        // Objc subclass
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, ObjcClass.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubclass.self, (Encodable & ProtocolA).self))
    }
    
    func testTypeCheckingForObjcSubclassFailure() {
        // Check failing cases
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, UnusedObjcClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, SwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, NSCoding.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, Decodable.self))
    }
    
    func testTypeCheckingForPureObjcClass() {
        // Objc class
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, ObjcViewController.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, (Encodable & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, (NSCoding & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, (NSCoding & Encodable).self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, ObjcViewInput.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, ObjcViewSubInput.self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, (ObjcViewInput & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(ObjcViewController.self, (ObjcViewSubInput & ProtocolA).self))
        
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, ObjcViewController.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, (Encodable & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, (NSCoding & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, (NSCoding & Encodable).self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, ObjcViewInput.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, ObjcViewSubInput.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, (ObjcViewInput & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubViewController.self, (ObjcViewSubInput & ProtocolA).self))
        
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, ObjcViewController.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, (Encodable & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, (NSCoding & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, (NSCoding & Encodable).self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, ObjcViewInput.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, ObjcViewSubInput.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, (ObjcViewInput & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcViewController<Any>.self, (ObjcViewSubInput & ProtocolA).self))
        
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, ObjcService.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, (Encodable & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, ObjcServiceInput.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, ObjcServiceSubInput.self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, (ObjcServiceInput & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(ObjcService.self, (ObjcServiceSubInput & ProtocolA).self))
        
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, ObjcService.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, (Encodable & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, ObjcServiceInput.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, ObjcServiceSubInput.self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, (ObjcServiceInput & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(ObjcSubService.self, (ObjcServiceSubInput & ProtocolA).self))
        
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, ObjcService.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, ObjcClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, SwiftClassSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, (Encodable & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, ObjcServiceInput.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, ObjcServiceSubInput.self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, (ObjcServiceInput & ProtocolA).self))
        XCTAssert(_swift_typeIsTargetType(GenericObjcClass<Any>.self, (ObjcServiceSubInput & ProtocolA).self))
    }
    
    func testTypeCheckingForPureObjcClassFailure() {
        // Check failing cases
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, UnusedObjcClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, SwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, Decodable.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, ObjcServiceInput.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcViewController.self, ObjcServiceSubInput.self))
        
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, UnusedObjcClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, SwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, NSCoding.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, Decodable.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, ObjcViewInput.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcService.self, ObjcViewSubInput.self))
    }
    
    func testTypeCheckingForSwiftStruct() {
        // Swift struct
        XCTAssert(_swift_typeIsTargetType(SwiftStruct.self, SwiftStruct.self))
        XCTAssert(_swift_typeIsTargetType(SwiftStruct.self, SwiftStructProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftStruct.self, SwiftStructSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftStruct.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(SwiftStruct.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(SwiftStruct.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftStruct.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(SwiftStruct.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(SwiftStruct.self, (Encodable & ProtocolA).self))
    }
    
    func testTypeCheckingForSwiftStructFailure() {
        // Check failing cases
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, UnusedObjcClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, UnusedSwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, SwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, NSCoding.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, Decodable.self))
    }
    
    func testTypeCheckingForSwiftEnum() {
        // Swift enum
        XCTAssert(_swift_typeIsTargetType(SwiftEnum.self, SwiftEnum.self))
        XCTAssert(_swift_typeIsTargetType(SwiftEnum.self, SwiftEnumProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftEnum.self, SwiftEnumSubProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftEnum.self, ProtocolA.self))
        XCTAssert(_swift_typeIsTargetType(SwiftEnum.self, ProtocolB.self))
        XCTAssert(_swift_typeIsTargetType(SwiftEnum.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(SwiftEnum.self, (ProtocolA & ProtocolB).self))
        XCTAssert(_swift_typeIsTargetType(SwiftEnum.self, Encodable.self))
        XCTAssert(_swift_typeIsTargetType(SwiftEnum.self, (Encodable & ProtocolA).self))
    }
    
    func testTypeCheckingForSwiftEnumFailure() {
        // Check failing cases
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, UnusedObjcClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, UnusedSwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, UnusedGenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, UnusedSwiftEnum.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, NSCoding.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, (Decodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, Decodable.self))
    }
    
    func testTypeCheckingForProtocol() {
        // Protocol
        XCTAssert(_swift_typeIsTargetType(SwiftClassProtocol.self, SwiftClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ComposedProtocol.self, ComposedProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClassProtocol.self, ObjcClassProtocol.self))
        XCTAssert(_swift_typeIsTargetType(ObjcClassSubProtocol.self, ObjcClassProtocol.self))
        
        // Can't check swift sub protocol
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassSubProtocol.self, SwiftClassProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ProtocolA.self, ComposedProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ProtocolB.self, ComposedProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(Encodable.self, Codable.self))
    }
    
    func testTypeCheckingForProtocolFailure() {
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, ComposedProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, Encodable.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, (Encodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, ObjcClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, SwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, GenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, SwiftEnum.self))
        
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, ComposedProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, Encodable.self))
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, (Encodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, ObjcClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, SwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, GenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(Decodable.self, SwiftEnum.self))
        
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, SwiftClassProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, ComposedProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, Encodable.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, (Encodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, ObjcClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, SwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, GenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, SwiftEnum.self))
        
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, UnusedObjcProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, UnusedSwiftProtocol.self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, (SwiftClassProtocol & UnusedSwiftProtocol).self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, Encodable.self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, Codable.self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, (Encodable & ProtocolA).self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, ObjcClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, SwiftClass.self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, GenericClass<Any>.self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, SwiftStruct.self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, SwiftEnum.self))
    }
    
    func testTypeCheckingForFunction() {
        // Function
        XCTAssert(_swift_typeIsTargetType(type(of: testTypeCheckingForFunction.self), type(of: testTypeCheckingForFunction.self)))
        XCTAssert(_swift_typeIsTargetType(SwiftClass.encode.self, SwiftClass.encode.self))
    }
    
    func testTypeCheckingForFunctionFailure() {
        XCTAssertFalse(_swift_typeIsTargetType(testTypeCheckingForFunction.self, type(of: testTypeCheckingForFunction.self)))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.encode.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassSubProtocol.self, testTypeCheckingForFunction.self))
        XCTAssertFalse(_swift_typeIsTargetType(Encodable.self, testTypeCheckingForFunction.self))
    }
    
    func testTypeCheckingForTuple() {
        // Tuple
        XCTAssert(_swift_typeIsTargetType((1, 2), (1, 2)))
        XCTAssert(_swift_typeIsTargetType(type(of: (1, 2)), type(of: (1, 2))))
    }
    
    func testTypeCheckingForTupleFailure() {
        XCTAssertFalse(_swift_typeIsTargetType((1, 2), type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftSubclass.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(GenericClass<Any>.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(SubGenericClass.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(GenericSubclass<Any>.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClass.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcSubclass.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftStruct.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftEnum.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClass.encode.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(SwiftClassProtocol.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(ComposedProtocol.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassProtocol.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(ObjcClassSubProtocol.self, type(of: (1, 2))))
        XCTAssertFalse(_swift_typeIsTargetType(Encodable.self, type(of: (1, 2))))
    }
    
    func testInvalidTypeChecking() {
        let types: [Any] = [SwiftClass.self, type(of: SwiftClass.self),
                            ObjcClass.self, type(of: ObjcClass.self),
                            SwiftStruct.self, SwiftStruct(), type(of: SwiftStruct.self),
                            SwiftEnum.self, SwiftEnum.case1, type(of: SwiftEnum.self),
                            (1, 2), (Int, Int).self, type(of: (Int, Int).self),
                            testTypeCheckingForFunction.self, type(of: testTypeCheckingForFunction.self)]
        
        for source in types {
            for target in types {
                if type(of: source) != type(of: target) {
                    XCTAssertFalse(_swift_typeIsTargetType(source, target), "source: \(source), should not be target: \(target)")
                }
            }
        }
    }
    
    func testEnumerateDeclaredProtocol() {
        measure {
            var symbolNames = [String]()
            _enumerateSymbolName { (name, demangledAsSwift) -> Bool in
                if (strstr(name, "RoutableView") != nil) {
                    let symbolName = demangledAsSwift(name, false)
                    if symbolName.contains("(extension in"), symbolName.contains(">.init"), symbolName.contains("(extension in ZRouter)") == false {
                        let simplifiedName = demangledAsSwift(name, true)
                        symbolNames.append(simplifiedName)
                    }
                }
                return true
            }
        }
    }
    
    func testDemangleSwiftSymbol() {
        measure {
            _enumerateSymbolName { (name, demangledAsSwift) -> Bool in
                if (strstr(name, "AViewModuleInput") != nil) {
                    let symbolName = demangledAsSwift(name, false)
                    let simplifiedName = demangledAsSwift(name, true)
                    assert(simplifiedName.contains(".") == false, "Simplified swift name (\(simplifiedName)) should not contain module name. Full symbol name is \(symbolName)")
                }
                return true
            }
        }
    }
    
    func testEnumerateSubclasses() {
        var count = 0
        ZIKRouter_enumerateClassList { (aClass) in
            if ZIKRouter_classIsSubclassOfClass(aClass, ZIKRouter<AnyObject, ZIKPerformRouteConfiguration, ZIKRemoveRouteConfiguration>.self) {
                count = count + 1
            }
        }
        var routerCount = 0
        enumerateClassesInMainBundleForParentClass(ZIKRouter<AnyObject, ZIKPerformRouteConfiguration, ZIKRemoveRouteConfiguration>.self) { (aClass) in
            routerCount = routerCount + 1
        }
        assert(routerCount == count, "enumerateSubclassesOfClass give wrong number of subclasses")
    }
    
    func testEnumerateAllViewRouters() {
        var routerCount = 0
        enumerateClassesInMainBundleForParentClass(ZIKAnyViewRouter.self) { (aClass) in
            routerCount = routerCount + 1
        }
        var enumeratedRouterCount = 0
        Router.enumerateAllViewRouters { (routerType) in
            enumeratedRouterCount = enumeratedRouterCount + 1
        }
        assert(enumeratedRouterCount > 0 && enumeratedRouterCount <= routerCount, "enumerate all routers not work properly")
    }
    
    func testEnumerateAllServiceRouters() {
        var routerCount = 0
        enumerateClassesInMainBundleForParentClass(ZIKAnyServiceRouter.self) { (aClass) in
            routerCount = routerCount + 1
        }
        var enumeratedRouterCount = 0
        Router.enumerateAllServiceRouters { (routerType) in
            enumeratedRouterCount = enumeratedRouterCount + 1
        }
        assert(enumeratedRouterCount > 0 && enumeratedRouterCount <= routerCount, "enumerate all routers not work properly")
    }
    
}
#endif

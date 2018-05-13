//
//  UtilityTests.swift
//  ZRouterTests
//
//  Created by zuik on 2018/5/11.
//  Copyright © 2018 zuik. All rights reserved.
//

import XCTest
import ZIKRouter.Private

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

class UtilityTests: XCTestCase {
    
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
}

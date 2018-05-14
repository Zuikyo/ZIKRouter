//
//  ZIKRouterRuntimeDebug.m
//  ZIKRouter
//
//  Created by zuik on 2018/5/12.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouterRuntimeDebug.h"
#import "ZIKRouterRuntime.h"
#import "ZIKImageSymbol.h"
#import <objc/runtime.h>

#if DEBUG

/**
 Check whether a type conforms to the given protocol. Use private C++ function inside libswiftCore.dylib:
 `bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)`.
 
 @return The function pointer of _conformsToProtocols().
 */
static bool(*swift_conformsToProtocols())(uintptr_t, uintptr_t, uintptr_t, uintptr_t*) {
    static void *_conformsToProtocols = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"\nZIKRouter:: _swift_typeConformsToProtocol():\nStart searching function pointer for\n`bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)` in libswiftCore.dylib to validate swift type.\n");
        
        ZIKImageRef libswiftCoreImage = [ZIKImageSymbol imageByName:"libswiftCore.dylib"];
        _conformsToProtocols = [ZIKImageSymbol findSymbolInImage:libswiftCoreImage matching:^BOOL(const char * _Nonnull symbolName) {
            if(strstr(symbolName, "_conformsToProtocols") &&
               strstr(symbolName, "OpaqueValue") &&
               strstr(symbolName, "TargetMetadata") &&
               strstr(symbolName, "WitnessTable")) {
                return YES;
            }
            return NO;
        }];
        NSCAssert(_conformsToProtocols != NULL, @"Can't find _conformsToProtocols in libswiftCore.dylib. You should use swift 3.3 or higher.");
        NSCAssert1([[ZIKImageSymbol symbolNameForAddress:_conformsToProtocols] containsString:@"OpaqueValue"] &&
                   [[ZIKImageSymbol symbolNameForAddress:_conformsToProtocols] containsString:@"TargetMetadata"] &&
                   [[ZIKImageSymbol symbolNameForAddress:_conformsToProtocols] containsString:@"WitnessTable"]
                   , @"The symbol name is not matched: %@", [ZIKImageSymbol symbolNameForAddress:_conformsToProtocols]);
        NSLog(@"\n✅ZIKRouter: function pointer address 0x%lx is found for `_conformsToProtocols`.\n",(long)_conformsToProtocols);
    });
    
    return (bool(*)(uintptr_t, uintptr_t, uintptr_t, uintptr_t*))_conformsToProtocols;
}

static uintptr_t dereferencedPointer(uintptr_t pointer) {
    uintptr_t **deref = (uintptr_t **)pointer;
    return (uintptr_t)*deref;
}

typedef NS_ENUM(NSInteger, ZIKSwiftMetadataKind) {
    ZIKSwiftMetadataKindClass                    = 0,
    ZIKSwiftMetadataKindStruct                   = 1,
    ZIKSwiftMetadataKindEnum                     = 2,
    ZIKSwiftMetadataKindOptional                 = 3,
    ZIKSwiftMetadataKindOpaque                   = 8,
    ZIKSwiftMetadataKindTuple                    = 9,
    ZIKSwiftMetadataKindFunction                 = 10,
    ZIKSwiftMetadataKindExistential              = 12,
    ZIKSwiftMetadataKindMetatype                 = 13,
    ZIKSwiftMetadataKindObjCClassWrapper         = 14,
    ZIKSwiftMetadataKindExistentialMetatype      = 15,
    ZIKSwiftMetadataKindForeignClass             = 16,
    ZIKSwiftMetadataKindHeapLocalVariable        = 64,
    ZIKSwiftMetadataKindHeapGenericLocalVariable = 65,
    ZIKSwiftMetadataKindErrorObject              = 128
};

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

bool _swift_typeIsTargetType(id sourceType, id targetType) {
    //swift class or swift object
    BOOL isSourceSwiftObjectType = [sourceType isKindOfClass:NSClassFromString(@"SwiftObject")];
    BOOL isTargetSwiftObjectType = [targetType isKindOfClass:NSClassFromString(@"SwiftObject")];
    //swift struct or swift enum or swift protocol
    BOOL isSourceSwiftValueType = [sourceType isKindOfClass:NSClassFromString(@"_SwiftValue")];
    BOOL isTargetSwiftValueType = [targetType isKindOfClass:NSClassFromString(@"_SwiftValue")];
    BOOL isSourceSwiftType = isSourceSwiftObjectType || isSourceSwiftValueType;
    BOOL isTargetSwiftType = isTargetSwiftObjectType || isTargetSwiftValueType;
    
    if (isSourceSwiftValueType && isTargetSwiftValueType == NO) {
        return false;
    }
    if ([sourceType isKindOfClass:NSClassFromString(@"Protocol")]) {
        if (isTargetSwiftType) {
            return false;
        }
        if ([targetType isKindOfClass:NSClassFromString(@"Protocol")]) {
            return protocol_conformsToProtocol(sourceType, targetType);
        } else {
            if (targetType == NSClassFromString(@"Protocol")) {
                return true;
            }
            return false;
        }
    }
    if ([targetType isKindOfClass:NSClassFromString(@"Protocol")]) {
        if (object_isClass(sourceType)) {
            return [sourceType conformsToProtocol:targetType];
        }
        return false;
    }
    if ((isSourceSwiftObjectType && object_isClass(sourceType) == NO) ||
        (isSourceSwiftType == NO && object_isClass(sourceType) == NO)) {
        NSCAssert(NO, @"This function only accept type parameter, not instance parameter.");
        return false;
    }
    if ((isTargetSwiftObjectType && object_isClass(targetType) == NO) ||
        (isTargetSwiftType == NO && object_isClass(targetType) == NO)) {
        NSCAssert(NO, @"This function only accept type parameter, not instance parameter.");
        return false;
    }
    
    if (object_isClass(sourceType) && object_isClass(targetType)) {
        return [sourceType isSubclassOfClass:targetType] || sourceType == targetType;
    } else if (isSourceSwiftValueType && isTargetSwiftValueType) {
        NSString *sourceTypeName = [sourceType performSelector:NSSelectorFromString(@"_swiftTypeName")];
        NSString *targetTypeName = [targetType performSelector:NSSelectorFromString(@"_swiftTypeName")];
        if ([sourceTypeName isEqualToString:targetTypeName]) {
            return true;
        }
    }
    
    bool (*_conformsToProtocols)(uintptr_t, uintptr_t, uintptr_t, uintptr_t*) = swift_conformsToProtocols();
    if (_conformsToProtocols == NULL) {
        return false;
    }
    
    uintptr_t sourceTypeOpaqueValue;
    uintptr_t sourceTypeMetadata;
    if (isSourceSwiftObjectType) {
        //swift class or swift object
        sourceTypeMetadata = (uintptr_t)(sourceType);
        sourceTypeOpaqueValue = (uintptr_t)(sourceType);
    } else if (isSourceSwiftValueType) {
        //swift struct or swift enum or swift protocol
        NSCAssert2([sourceType respondsToSelector:NSSelectorFromString(@"_swiftValue")], @"Swift value(%@) doesn't have method(%@), the API may be changed in libswiftCore.dylib.",sourceType,@"_swiftValue");
        sourceTypeOpaqueValue = (uintptr_t)[sourceType performSelector:NSSelectorFromString(@"_swiftValue")];
        //Get type metadata of this value, like `type(of: T)`
        sourceTypeMetadata = (uintptr_t)[sourceType performSelector:NSSelectorFromString(@"_swiftTypeMetadata")];
        //Get the first member `Kind` in TargetMetadata, it's an enum `MetadataKind`
        ZIKSwiftMetadataKind type = (ZIKSwiftMetadataKind)dereferencedPointer(sourceTypeMetadata);
        //Source is a metatype, get it's metadata
        if (type == ZIKSwiftMetadataKindMetatype) {
            //OpaqueValue is struct SwiftValueHeader, `Metadata *` is it's first member
            sourceTypeMetadata = dereferencedPointer(sourceTypeOpaqueValue);
        }
    } else {
        //objc class or objc protocol
        sourceTypeMetadata = (uintptr_t)sourceType;
        sourceTypeOpaqueValue = (uintptr_t)sourceType;
    }
    
    uintptr_t targetTypeOpaqueValue;
    uintptr_t targetTypeMetadata;
    uintptr_t targetWitnessTables = 0;
    if (isTargetSwiftValueType) {
        //swift struct or swift enum or swift protocol
        NSCAssert2([targetType respondsToSelector:NSSelectorFromString(@"_swiftValue")], @"Swift value(%@) doesn't have method(%@), the API may be changed in libswiftCore.dylib.",targetType,@"_swiftValue");
        targetTypeOpaqueValue = (uintptr_t)[targetType performSelector:NSSelectorFromString(@"_swiftValue")];
        //Get type metadata of this value, like `type(of: T)`
        targetTypeMetadata = (uintptr_t)[targetType performSelector:NSSelectorFromString(@"_swiftTypeMetadata")];
        //Get the first member `Kind` in TargetMetadata, it's an enum `MetadataKind`
        ZIKSwiftMetadataKind type = (ZIKSwiftMetadataKind)dereferencedPointer(targetTypeMetadata);
        //Target is a metatype, get it's metadata
        if (type == ZIKSwiftMetadataKindMetatype) {
            //OpaqueValue is struct SwiftValueHeader, `Metadata *` is it's first member
            targetTypeMetadata = dereferencedPointer(targetTypeOpaqueValue);
            type = (ZIKSwiftMetadataKind)dereferencedPointer(targetTypeMetadata);
        }
        //target should be swift protocol
        if (type != ZIKSwiftMetadataKindExistential) {
            return false;
        }
    } else {
        //objc protocol
        if ([targetType isKindOfClass:NSClassFromString(@"Protocol")] == NO) {
            return false;
        }
        targetTypeMetadata = (uintptr_t)targetType;
        targetTypeOpaqueValue = (uintptr_t)targetType;
    }
    
    bool result = _conformsToProtocols(sourceTypeOpaqueValue, sourceTypeMetadata, targetTypeMetadata, &targetWitnessTables);
    return result;
}

#pragma clang diagnostic pop

#else

bool _swift_typeIsTargetType(id sourceType, id targetType) {
    return false;
}

#endif

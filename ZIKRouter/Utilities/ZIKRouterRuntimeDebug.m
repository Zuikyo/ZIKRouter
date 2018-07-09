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

#if DEBUG

#import "ZIKRouterRuntime.h"
#import "ZIKImageSymbol.h"
#import <objc/runtime.h>
#import "NSString+Demangle.h"

/**
 Check whether a type conforms to the given protocol. Use private C++ function inside libswiftCore.dylib:
 `bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)`.
 
 @return The function pointer of _conformsToProtocols().
 */
static bool swift_conformsToProtocols(uintptr_t value, uintptr_t type, uintptr_t existentialType, uintptr_t* conformances) {
    static bool(*_conformsToProtocols)(uintptr_t, uintptr_t, uintptr_t, uintptr_t*) = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
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
    });
    if (_conformsToProtocols == NULL) {
        return false;
    }
    return _conformsToProtocols(value, type, existentialType, conformances);
}

static bool _objcClassConformsToSwiftProtocolName(Class objcClass, NSString *swiftProtocolName) {
    NSCAssert1([swiftProtocolName containsString:@"."], @"Invalid swift protocol name: %@", swiftProtocolName);
    static NSMutableSet<NSString *> *conformancesCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        conformancesCache = [NSMutableSet set];
    });
    __block BOOL conform = NO;
    NSString *className = NSStringFromClass(objcClass);
    NSString *record = [[className stringByAppendingString:@"_"] stringByAppendingString:swiftProtocolName];
    if ([conformancesCache containsObject:record]) {
        return true;
    }
    NSMutableArray<NSString *> *classNames = [NSMutableArray array];
    Class aClass = objcClass;
    while (aClass) {
        [classNames addObject:NSStringFromClass(aClass)];
        aClass = [aClass superclass];
    }
    
    // Handle composed protocol
    NSMutableSet<NSString *> *protocolNames = [NSMutableSet setWithArray:[swiftProtocolName componentsSeparatedByString:@" & "]];
    // Check objc protocol in composed protocol
    for (NSString *protocolName in [swiftProtocolName componentsSeparatedByString:@" & "]) {
        if ([protocolName hasPrefix:@"__ObjC."]) {
            NSString *objcProtocolName = [protocolName substringFromIndex:7];
            Protocol *objcProtocol = NSProtocolFromString(objcProtocolName);
            if (objcProtocol) {
                if ([objcClass conformsToProtocol:objcProtocol]) {
                    [protocolNames removeObject:protocolName];
                } else {
                    return false;
                }
            }
        }
    }
    NSInteger protocolCount = protocolNames.count;
    NSMutableSet<NSString *> *conformedProtocolNames = [NSMutableSet set];
        
    _enumerateSymbolName(^bool(const char * _Nonnull name, NSString * _Nonnull (^ _Nonnull demangledAsSwift)(const char * _Nonnull, bool)) {
        size_t str_len = strlen(name);
        if (str_len <= 3) {
            return YES;
        }
        // swift mangled symbol
        if(strncmp("__T", name, 3) != 0) {
            return YES;
        }
        // suffix for protocol witness table: WP
        // suffix for generic protocol witness table: WG
        char *suffix = "WP";
        size_t suffix_len = strlen(suffix);
        BOOL isProtocolWitnessTable = (0 == strcmp(name + (str_len - suffix_len), suffix));
        if (isProtocolWitnessTable == NO) {
            return YES;
        }
        NSString *containedClassName = nil;
        for (NSString *className in classNames) {
            if (strstr(name, className.UTF8String)) {
                containedClassName = className;
                break;
            }
        }
        if (containedClassName == nil) {
            return YES;
        }
        NSString *demangledName = demangledAsSwift(name, false);
        if ([demangledName containsString:@"protocol witness table for"]) {

            for (NSString *protocolName in protocolNames) {
                if ([demangledName containsString:[NSString stringWithFormat:@"__ObjC.%@ : %@", containedClassName, protocolName]]) {
                    [conformedProtocolNames addObject:protocolName];
                    if (conformedProtocolNames.count == protocolCount) {
                        conform = YES;
                        [conformancesCache addObject:record];
                        return NO;
                    }
                }
            }
            
        }
        return YES;
    });
    return conform;
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
        //Source is a metatype, get its metadata
        if (type == ZIKSwiftMetadataKindMetatype || type == ZIKSwiftMetadataKindExistentialMetatype) {
            //OpaqueValue is struct SwiftValueHeader, `Metadata *` is its first member
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
        //Target is a metatype, get its metadata
        if (type == ZIKSwiftMetadataKindMetatype || type == ZIKSwiftMetadataKindExistentialMetatype) {
            //OpaqueValue is struct SwiftValueHeader, `Metadata *` is its first member
            targetTypeMetadata = dereferencedPointer(targetTypeOpaqueValue);
            type = (ZIKSwiftMetadataKind)dereferencedPointer(targetTypeMetadata);
        }
        //target should be swift protocol
        if (type != ZIKSwiftMetadataKindExistential) {
            return false;
        } else {
            //For pure objc class, can't check conformance with swift_conformsToProtocols, need to use swift type metadata of this class as sourceTypeMetadata, or just search protocol witness table for this class
            if (object_isClass(sourceType) && isSourceSwiftObjectType == NO &&
                [[NSStringFromClass(sourceType) demangledAsSwift] containsString:@"."] == NO) {
                static void*(*swift_getObjCClassMetadata)(void*);
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    ZIKImageRef libswiftCoreImage = [ZIKImageSymbol imageByName:"libswiftCore.dylib"];
                    swift_getObjCClassMetadata = [ZIKImageSymbol findSymbolInImage:libswiftCoreImage name:"_swift_getObjCClassMetadata"];
                });
                if (swift_getObjCClassMetadata) {
                    sourceTypeMetadata = (uintptr_t)swift_getObjCClassMetadata((__bridge void *)(sourceType));
                } else {
                    return _objcClassConformsToSwiftProtocolName(sourceType, [targetType description]);
                }
            }
        }
    } else {
        //objc protocol
        if ([targetType isKindOfClass:NSClassFromString(@"Protocol")] == NO) {
            return false;
        }
        targetTypeMetadata = (uintptr_t)targetType;
        targetTypeOpaqueValue = (uintptr_t)targetType;
    }
    
    bool result = swift_conformsToProtocols(0, sourceTypeMetadata, targetTypeMetadata, &targetWitnessTables);
    return result;
}

#pragma clang diagnostic pop

void _enumerateSymbolName(bool(^handler)(const char *name, NSString *(^demangledAsSwift)(const char *mangledName, bool simplified))) {
    if (handler == nil) {
        return;
    }
    NSString *(^demangledAsSwift)(const char *, bool) = ^(const char *mangledName, bool simplified) {
        NSString *name = nil;
        if (mangledName == NULL) {
            return name;
        }
        name = [NSString stringWithUTF8String:mangledName];
        if ([name hasPrefix:@"_"]) {
            name = [name substringFromIndex:1];
        }
        NSString *demangled;
        if (simplified) {
            demangled = [name demangledAsSimplifiedSwift];
        } else {
            demangled = [name demangledAsSwift];
        }
        if (demangled) {
            return demangled;
        }
        return name;
    };
    
    [ZIKImageSymbol enumerateImages:^BOOL(ZIKImageRef  _Nonnull image, NSString * _Nonnull path) {
        if ([path containsString:@"/System/Library/"] == YES ||
            [path containsString:@"/usr/"] == YES ||
            ([path containsString:@"libswift"] && [path containsString:@"dylib"])) {
            return YES;
        }
        void *value = [ZIKImageSymbol findSymbolInImage:image matching:^BOOL(const char * _Nonnull symbolName) {
            return !handler(symbolName, demangledAsSwift);
        }];
        if (value != NULL) {
            return NO;
        }
        return YES;
    }];
}

#endif

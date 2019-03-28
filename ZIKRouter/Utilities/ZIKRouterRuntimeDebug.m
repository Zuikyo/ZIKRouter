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

@interface NSString (ZIXContainsString)
- (BOOL)zix_containsString:(NSString *)str;
@end
@implementation NSString (ZIXContainsString)
- (BOOL)zix_containsString:(NSString *)str {
    return [self rangeOfString:str].length != 0;
}
@end

#define MetadataKindIsNonType 0x400
#define MetadataKindIsNonHeap 0x200
#define MetadataKindIsRuntimePrivate 0x100

/// Swift ABI: MetadataKind.def
typedef NS_ENUM(NSInteger, ZIKSwiftMetadataKind) {
    ZIKSwiftMetadataKindClass_old                    = 0,
    ZIKSwiftMetadataKindStruct_old                   = 1,
    ZIKSwiftMetadataKindEnum_old                     = 2,
    ZIKSwiftMetadataKindOptional_old                 = 3,
    ZIKSwiftMetadataKindOpaque_old                   = 8,
    ZIKSwiftMetadataKindTuple_old                    = 9,
    ZIKSwiftMetadataKindFunction_old                 = 10,
    ZIKSwiftMetadataKindExistential_old              = 12,
    ZIKSwiftMetadataKindMetatype_old                 = 13,
    ZIKSwiftMetadataKindObjCClassWrapper_old         = 14,
    ZIKSwiftMetadataKindExistentialMetatype_old      = 15,
    ZIKSwiftMetadataKindForeignClass_old             = 16,
    ZIKSwiftMetadataKindHeapLocalVariable_old        = 64,
    ZIKSwiftMetadataKindHeapGenericLocalVariable_old = 65,
    ZIKSwiftMetadataKindErrorObject_old              = 128,
    
    /// ABI after Xcode 10.2 with Swift 5
    
    ZIKSwiftMetadataKindClass                    = 0,
    ZIKSwiftMetadataKindStruct                   = 0 | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindEnum                     = 1 | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindOptional                 = 2 | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindForeignClass             = 3 | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindOpaque                   = 0 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindTuple                    = 1 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindFunction                 = 2 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindExistential              = 3 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindMetatype                 = 4 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindObjCClassWrapper         = 5 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindExistentialMetatype      = 6 | MetadataKindIsRuntimePrivate | MetadataKindIsNonHeap,
    ZIKSwiftMetadataKindHeapLocalVariable        = 0 | MetadataKindIsNonType,
    ZIKSwiftMetadataKindHeapGenericLocalVariable = 0 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate,
    ZIKSwiftMetadataKindErrorObject              = 1 | MetadataKindIsNonType | MetadataKindIsRuntimePrivate
};

typedef struct {
    /// Unused by the Swift runtime.
    void *_ObjC_Isa;
    
    /// The mangled name of the protocol.
    char *Name;
    
    /// The list of protocols this protocol refines.
    void *InheritedProtocols;
    
} TargetProtocolDescriptor_Old;

static bool isObjCProtocolDescriptor(TargetProtocolDescriptor_Old *protocolDescriptor) {
    return protocolDescriptor->_ObjC_Isa != 0;
}

typedef struct {
    /// A direct pointer to a protocol descriptor for either an Objective-C
    /// protocol (if the low bit is set) or a Swift protocol (if the low bit
    /// is clear).
    uintptr_t storage;
    
} TargetProtocolDescriptorRef;

enum: uintptr_t {
    IsObjCBit = 0x1U,
};

static uintptr_t getProtocolWithProtocolDescriptorRef(TargetProtocolDescriptorRef protocolDescriptorRef) {
    return (protocolDescriptorRef.storage & ~IsObjCBit);
}

static bool isObjCProtocolDescriptorRef(TargetProtocolDescriptorRef protocolDescriptorRef) {
    return (protocolDescriptorRef.storage & IsObjCBit) != 0;
}

enum: uint32_t {
    NumWitnessTablesMask  = 0x00FFFFFFU,
    ClassConstraintMask   = 0x80000000U,
    HasSuperclassMask     = 0x40000000U,
    SpecialProtocolMask   = 0x3F000000U,
    SpecialProtocolShift  = 24U,
};

typedef struct  {
    uint32_t Data;
} ExistentialTypeFlags;

typedef struct  {
    size_t Data;
} ExistentialTypeFlags_Old;

static bool hasSuperclassConstraint(ExistentialTypeFlags flag) {
    return flag.Data & HasSuperclassMask;
}

typedef struct {
    ZIKSwiftMetadataKind Kind;
} TargetMetadata;

typedef struct {
    ZIKSwiftMetadataKind Kind;
    Class aClass;
} ObjCClassWrapperMetadata;

typedef union {
    TargetMetadata *targetMetadata;
    Class targetClass;
    TargetProtocolDescriptorRef protocolDescriptorRef; // Swift 5
    TargetProtocolDescriptor_Old *protocolDescriptor; // Swift 4
} ExistentialTypeMetadataEntry;

typedef struct {
    ZIKSwiftMetadataKind Kind;
    /// The number of witness tables and class-constrained-ness of the type.
    ExistentialTypeFlags Flags;
    
    /// The number of protocols.
    uint32_t NumProtocols;
    
    /// Size is NumProtocols
    ExistentialTypeMetadataEntry protocols[];
} ExistentialTypeMetadata; // Swift 5

typedef struct {
    ZIKSwiftMetadataKind Kind;
    /// The number of witness tables and class-constrained-ness of the type.
    ExistentialTypeFlags_Old Flags;
    
    /// The number of protocols.
    size_t NumProtocols;
    
    /// Size is NumProtocols
    ExistentialTypeMetadataEntry protocols[];
} ExistentialTypeMetadata_Old; // Swift 4

typedef struct {
    TargetMetadata *metadata;
} SwiftValueHeader;

static TargetMetadata *swift_dynamicCastMetatype(TargetMetadata *sourceType, TargetMetadata *targetType) {
    static TargetMetadata*(*_swift_dynamicCastMetatype)(TargetMetadata *, TargetMetadata *) = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKImageRef libswiftCoreImage = [ZIKImageSymbol imageByName:"libswiftCore.dylib"];
        _swift_dynamicCastMetatype = (TargetMetadata*(*)(TargetMetadata *, TargetMetadata *))[ZIKImageSymbol findSymbolInImage:libswiftCoreImage name:"_swift_dynamicCastMetatype"];
    });
    if (!_swift_dynamicCastMetatype) {
        return NULL;
    }
    return _swift_dynamicCastMetatype(sourceType, targetType);
}

static bool swift_conformsToProtocols(bool isSourceClassType, TargetMetadata *type, ExistentialTypeMetadata *existentialType, uintptr_t* conformances) {
    static uintptr_t(*_swift_conformsToProtocol)(TargetMetadata *, uintptr_t) = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ZIKImageRef libswiftCoreImage = [ZIKImageSymbol imageByName:"libswiftCore.dylib"];
        _swift_conformsToProtocol = (uintptr_t(*)(TargetMetadata *, uintptr_t))[ZIKImageSymbol findSymbolInImage:libswiftCoreImage name:"_swift_conformsToProtocol"];
    });
    if (_swift_conformsToProtocol == NULL) {
        return false;
    }
    
    /*
     ExistentialTypeMetadata layout after Xcode 10.2 with Swift 5:
     
     member       |    size (64-bit / 32-bit)
     
     kind           8 bit / 4 bit
     flags          4 bit
     numProtocols   4 bit
     superclass     8 bit / 4 bit   // Metadata* or ObjCClassWrapperMetadata* or Class.
                                    // Class constraint in protocol composition. If there's no class constraint, this doesn't exist
     protocol1      8 bit / 4 bit   // ProtocolDescriptorRef or Protocol*
     protocol2      8 bit / 4 bit   // ProtocolDescriptorRef or Protocol*
     ...                            // The size is numProtocols
     00000000                       // End with zero
     
     
     ExistentialTypeMetadata layout before Xcode 10.2 and Swift 4.2:
     
     member       |    size (64-bit / 32-bit)
     
     kind           8 bit / 4 bit
     flags          8 bit / 4 bit
     numProtocols   8 bit / 4 bit
     protocol1      8 bit / 4 bit   // ProtocolDescriptor or Protocol*
     protocol2      8 bit / 4 bit   // ProtocolDescriptor or Protocol*
     ...                            // The size is numProtocols
     superclass     8 bit / 4 bit   // Metadata* or ObjCClassWrapperMetadata* or Class.
                                    // Class constraint in protocol composition. If there's no class constraint, this doesn't exist
     00000000                       // End with zero
     */
    
    int32_t startIdx = 0;
    int32_t maxIdx = 0;
    bool isSwift5 = (existentialType->Kind != ZIKSwiftMetadataKindExistential_old);
    
    if (!isSwift5) {
        size_t NumProtocols = ((ExistentialTypeMetadata_Old *)existentialType)->NumProtocols;
        maxIdx = (int)NumProtocols - 1;
    } else {
        maxIdx = existentialType->NumProtocols - 1;
    }
    
    // Target is a protocol composition: UIViewController & SomeProtocol
    if (hasSuperclassConstraint(existentialType->Flags)) {
        if (!isSourceClassType &&
            type->Kind != ZIKSwiftMetadataKindObjCClassWrapper &&
            type->Kind != ZIKSwiftMetadataKindObjCClassWrapper_old) {
            return false;
        }
        
        int classIdx = 0;
        if (!isSwift5) {
            size_t NumProtocols = ((ExistentialTypeMetadata_Old *)existentialType)->NumProtocols;
            // The class constraint is at the end of the list
            classIdx = (int)NumProtocols;
            startIdx = 0;
            maxIdx = (int)NumProtocols - 1;
        } else {
            // The class constraint is at the head of the list
            classIdx = 0;
            startIdx = 1;
            maxIdx = existentialType->NumProtocols - 1 + startIdx;            
        }
        
        TargetMetadata *targetMetadata = NULL;
        if (!isSwift5) {
            targetMetadata = ((ExistentialTypeMetadata_Old *)existentialType)->protocols[classIdx].targetMetadata;
        } else {
            targetMetadata = existentialType->protocols[classIdx].targetMetadata;
        }
        if (targetMetadata->Kind == ZIKSwiftMetadataKindObjCClassWrapper ||
            targetMetadata->Kind == ZIKSwiftMetadataKindObjCClassWrapper_old) {
            // Target is Metadata wrapper for pure objc class
            Class sourceClass = nil;
            if (isSourceClassType) {
                sourceClass = (__bridge Class)type;
            } else if (type->Kind == ZIKSwiftMetadataKindObjCClassWrapper ||
                       type->Kind == ZIKSwiftMetadataKindObjCClassWrapper_old) {
                sourceClass = ((ObjCClassWrapperMetadata *)type)->aClass;
            } else {
                return false;
            }
            Class targetClass = ((ObjCClassWrapperMetadata *)targetMetadata)->aClass;
            if (![sourceClass isSubclassOfClass:targetClass]) {
                return false;
            }
        } else if (targetMetadata->Kind > ZIKSwiftMetadataKindErrorObject) {
            // Target is Class
            Class sourceClass = nil;
            if (isSourceClassType) {
                sourceClass = (__bridge Class)type;
            } else if (type->Kind == ZIKSwiftMetadataKindObjCClassWrapper ||
                       type->Kind == ZIKSwiftMetadataKindObjCClassWrapper_old) {
                sourceClass = ((ObjCClassWrapperMetadata *)type)->aClass;
            } else {
                return false;
            }
            Class targetClass = nil;
            if (!isSwift5) {
                targetClass = ((ExistentialTypeMetadata_Old *)existentialType)->protocols[classIdx].targetClass;
            } else {
                targetClass = existentialType->protocols[classIdx].targetClass;
            }
            if (![sourceClass isSubclassOfClass:targetClass]) {
                return false;
            }
        } else if (!swift_dynamicCastMetatype(type, targetMetadata)) {
            // Target is Metadata*
            return false;
        }
    }
    
    // Check the protocol list
    for (int i = startIdx; i <= maxIdx; i++) {
        // Protocol format before Xcode 10.2 in Swift 4.2
        TargetProtocolDescriptor_Old *protocolDescriptor = NULL;
        // Protocol format after Xcode 10.2 in Swift 5
        TargetProtocolDescriptorRef protocolDescriptorRef = {0};
        if (!isSwift5) {
            protocolDescriptor = ((ExistentialTypeMetadata_Old *)existentialType)->protocols[i].protocolDescriptor;
            if (protocolDescriptor == NULL) {
                if (i == startIdx) {
                    return false;
                }
                break;
            }
        } else {
            protocolDescriptorRef = existentialType->protocols[i].protocolDescriptorRef;
            if (protocolDescriptorRef.storage == 0) {
                if (i == startIdx) {
                    return false;
                }
                break;
            }
        }
        
        // ObjC protocol is Protocol *
        bool isObjCProtocol = false;
        if (!isSwift5) {
            isObjCProtocol = isObjCProtocolDescriptor(protocolDescriptor);
        } else {
            isObjCProtocol = isObjCProtocolDescriptorRef(protocolDescriptorRef);
        }
        if (isObjCProtocol) {
            Class sourceClass = nil;
            Protocol *targetProtocol;
            if (!isSwift5) {
                targetProtocol = (__bridge Protocol *)protocolDescriptor;
            } else {
                targetProtocol = (__bridge Protocol *)(void *)getProtocolWithProtocolDescriptorRef(protocolDescriptorRef);
            }
            
            // Get class
            if (isSourceClassType) {
                sourceClass = (__bridge Class)type;
            } else {
                switch (type->Kind) {
                    case ZIKSwiftMetadataKindClass: {
                        sourceClass = (__bridge Class)type;
                        break;
                    }
                    case ZIKSwiftMetadataKindObjCClassWrapper:
                    case ZIKSwiftMetadataKindObjCClassWrapper_old: {
                        ObjCClassWrapperMetadata *sourceType = (ObjCClassWrapperMetadata *)type;
                        sourceClass = sourceType->aClass;
                        break;
                    }
                    default:
                        return false;
                        break;
                }
            }
            
            if (![sourceClass conformsToProtocol:targetProtocol]) {
                return false;
            }
        } else {
            // Get ProtocolDescriptor
            uintptr_t protocol;
            if (!isSwift5) {
                protocol = (uintptr_t)protocolDescriptor;
            } else {
                protocol = getProtocolWithProtocolDescriptorRef(protocolDescriptorRef);
            }
            uintptr_t result = _swift_conformsToProtocol(type, protocol);
            if (result == 0) {
                return false;
            }
        }
    }
    
    return true;
}

static BOOL object_is_class(id obj) {
    if ([obj class] == obj) {
        return YES;
    }
    return NO;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

bool _swift_typeIsTargetType(id sourceType, id targetType) {
    //swift class or swift object
    BOOL isSourceSwiftObjectType = [sourceType isKindOfClass:NSClassFromString(@"SwiftObject")] || [sourceType isKindOfClass:NSClassFromString(@"Swift._SwiftObject")];
    BOOL isTargetSwiftObjectType = [targetType isKindOfClass:NSClassFromString(@"SwiftObject")] || [targetType isKindOfClass:NSClassFromString(@"Swift._SwiftObject")];
    //swift struct or swift enum or swift protocol
    BOOL isSourceSwiftValueType = [sourceType isKindOfClass:NSClassFromString(@"_SwiftValue")] || [sourceType isKindOfClass:NSClassFromString(@"__SwiftValue")];
    BOOL isTargetSwiftValueType = [targetType isKindOfClass:NSClassFromString(@"_SwiftValue")] || [targetType isKindOfClass:NSClassFromString(@"__SwiftValue")];
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
        if (object_is_class(sourceType)) {
            return [sourceType conformsToProtocol:targetType];
        }
        return false;
    }
    if ((isSourceSwiftObjectType && object_is_class(sourceType) == NO) ||
        (isSourceSwiftType == NO && object_is_class(sourceType) == NO)) {
        NSCAssert(NO, @"This function only accept type parameter, not instance parameter.");
        return false;
    }
    if ((isTargetSwiftObjectType && object_is_class(targetType) == NO) ||
        (isTargetSwiftType == NO && object_is_class(targetType) == NO)) {
        NSCAssert(NO, @"This function only accept type parameter, not instance parameter.");
        return false;
    }
    
    if (object_is_class(sourceType) && object_is_class(targetType)) {
        return [sourceType isSubclassOfClass:targetType] || sourceType == targetType;
    } else if (isSourceSwiftValueType && isTargetSwiftValueType) {
        NSString *sourceTypeName = [sourceType performSelector:NSSelectorFromString(@"_swiftTypeName")];
        NSString *targetTypeName = [targetType performSelector:NSSelectorFromString(@"_swiftTypeName")];
        if ([sourceTypeName isEqualToString:targetTypeName]) {
            return true;
        }
    }
    bool isSourceClassType = false;
    SwiftValueHeader *sourceTypeOpaqueValue;
    TargetMetadata *sourceTypeMetadata;
    if (isSourceSwiftObjectType) {
        //swift class or swift object
        sourceTypeMetadata = (__bridge TargetMetadata *)(sourceType);
        sourceTypeOpaqueValue = (__bridge SwiftValueHeader *)(sourceType);
        isSourceClassType = true;
    } else if (isSourceSwiftValueType) {
        //swift struct or swift enum or swift protocol
        NSCAssert2([sourceType respondsToSelector:NSSelectorFromString(@"_swiftValue")], @"Swift value(%@) doesn't have method(%@), the API may be changed in libswiftCore.dylib.",sourceType,@"_swiftValue");
        sourceTypeOpaqueValue = (__bridge SwiftValueHeader *)[sourceType performSelector:NSSelectorFromString(@"_swiftValue")];
        //Get type metadata of this value, like `type(of: T)`
        sourceTypeMetadata = (__bridge TargetMetadata *)[sourceType performSelector:NSSelectorFromString(@"_swiftTypeMetadata")];
        //Get the first member `Kind` in TargetMetadata, it's an enum `MetadataKind`
        ZIKSwiftMetadataKind type = sourceTypeMetadata->Kind;
        //Source is a metatype, get its metadata
        if (type == ZIKSwiftMetadataKindMetatype || type == ZIKSwiftMetadataKindExistentialMetatype || type == ZIKSwiftMetadataKindMetatype_old || type == ZIKSwiftMetadataKindExistentialMetatype_old) {
            //OpaqueValue is struct SwiftValueHeader, `Metadata *` is its first member
            sourceTypeMetadata = sourceTypeOpaqueValue->metadata;
        }
    } else {
        //objc class or objc protocol
        sourceTypeMetadata = (__bridge TargetMetadata *)(sourceType);
        sourceTypeOpaqueValue = (__bridge SwiftValueHeader *)(sourceType);
        isSourceClassType = true;
    }
    
    SwiftValueHeader *targetTypeOpaqueValue;
    TargetMetadata *targetTypeMetadata;
    uintptr_t targetWitnessTables = 0;
    if (isTargetSwiftValueType) {
        //swift struct or swift enum or swift protocol
        NSCAssert2([targetType respondsToSelector:NSSelectorFromString(@"_swiftValue")], @"Swift value(%@) doesn't have method(%@), the API may be changed in libswiftCore.dylib.",targetType,@"_swiftValue");
        targetTypeOpaqueValue = (__bridge SwiftValueHeader *)[targetType performSelector:NSSelectorFromString(@"_swiftValue")];
        //Get type metadata of this value, like `type(of: T)`
        targetTypeMetadata = (__bridge TargetMetadata *)[targetType performSelector:NSSelectorFromString(@"_swiftTypeMetadata")];
        //Get the first member `Kind` in TargetMetadata, it's an enum `MetadataKind`
        ZIKSwiftMetadataKind type = targetTypeMetadata->Kind;
        //Target is a metatype, get its metadata
        if (type == ZIKSwiftMetadataKindMetatype || type == ZIKSwiftMetadataKindExistentialMetatype || type == ZIKSwiftMetadataKindMetatype_old || type == ZIKSwiftMetadataKindExistentialMetatype_old) {
            //OpaqueValue is struct SwiftValueHeader, `Metadata *` is its first member
            targetTypeMetadata = targetTypeOpaqueValue->metadata;
            type = targetTypeMetadata->Kind;
        }
        //target should be swift protocol
        if (type != ZIKSwiftMetadataKindExistential && type != ZIKSwiftMetadataKindExistential_old) {
            return false;
        } else {
            //For pure objc class, can't check conformance with swift_conformsToProtocols, need to use swift type metadata of this class as sourceTypeMetadata, or just search protocol witness table for this class
            if (object_is_class(sourceType) && isSourceSwiftObjectType == NO &&
                [[NSStringFromClass(sourceType) demangledAsSwift] zix_containsString:@"."] == NO) {
                static TargetMetadata *(*swift_getObjCClassMetadata)(void*);
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^{
                    ZIKImageRef libswiftCoreImage = [ZIKImageSymbol imageByName:"libswiftCore.dylib"];
                    swift_getObjCClassMetadata = (TargetMetadata*(*)(void*))[ZIKImageSymbol findSymbolInImage:libswiftCoreImage name:"_swift_getObjCClassMetadata"];
                });
                if (swift_getObjCClassMetadata) {
                    // type is ZIKSwiftMetadataKindObjCClassWrapper
                    sourceTypeMetadata = swift_getObjCClassMetadata((__bridge void *)(sourceType));
                    isSourceClassType = false;
                }
            }
        }
    } else {
        //objc protocol
        if ([targetType isKindOfClass:NSClassFromString(@"Protocol")] == NO) {
            return false;
        }
        targetTypeMetadata = (__bridge TargetMetadata *)targetType;
        targetTypeOpaqueValue = (__bridge SwiftValueHeader *)targetType;
    }
    
    bool result = swift_conformsToProtocols(isSourceClassType, (TargetMetadata *)sourceTypeMetadata, (ExistentialTypeMetadata *)targetTypeMetadata, &targetWitnessTables);
    return result;
}

#pragma clang diagnostic pop

bool zix_hasDynamicLibrary(NSString *libName) {
    const void *image = [ZIKImageSymbol imageByName:libName.UTF8String];
    return image != NULL;
}

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
        if ([path zix_containsString:@"/System/Library/"] == YES ||
            [path zix_containsString:@"/usr/"] == YES ||
            ([path zix_containsString:@"libswift"] && [path zix_containsString:@".dylib"])) {
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

#import "ZIKRouterInternal.h"
#import "ZIKRouteRegistryInternal.h"
#if __has_include("ZIKViewRouter.h")
#import "ZIKViewRouteRegistry.h"
#endif
#import "ZIKServiceRouteRegistry.h"

NSString *codeForImportingRouters() {
    NSMutableArray<Class> *objcViewRouters = [NSMutableArray array];
    NSMutableArray<Class> *objcViewAdapters = [NSMutableArray array];
    
    NSMutableArray<Class> *objcServiceRouters = [NSMutableArray array];
    NSMutableArray<Class> *objcServiceAdapters = [NSMutableArray array];
    
    ZIKRouter_enumerateClassList(^(__unsafe_unretained Class aClass) {
#if __has_include("ZIKViewRouter.h")
        if ([ZIKViewRouteRegistry isRegisterableRouterClass:aClass]) {
            if ([NSStringFromClass(aClass) zix_containsString:@"."]) {
                return;
            }
            if ([aClass isAdapter]) {
                [objcViewAdapters addObject:aClass];
            } else {
                [objcViewRouters addObject:aClass];
            }
        } else
#endif
        if ([ZIKServiceRouteRegistry isRegisterableRouterClass:aClass]) {
            if ([NSStringFromClass(aClass) zix_containsString:@"."]) {
                return;
            }
            if ([aClass isAdapter]) {
                [objcServiceAdapters addObject:aClass];
            } else {
                [objcServiceRouters addObject:aClass];
            }
        }
    });
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSMutableString *code = [NSMutableString string];
    
    void(^generateCodeForImportingRouters)(NSArray<Class> *) = ^(NSArray<Class> *routers) {
        for (Class aClass in routers) {
            NSBundle *bundle = [NSBundle bundleForClass:aClass];
            NSCAssert1(bundle, @"Failed to get bundle for class %@",NSStringFromClass(aClass));
            if ([bundle isEqual:mainBundle]) {
                [code appendFormat:@"\n#import \"%@.h\"",NSStringFromClass(aClass)];
            } else {
                NSString *bundleName = [bundle.infoDictionary objectForKey:(__bridge NSString *)kCFBundleNameKey];
                NSCAssert2(bundle, @"Failed to get bundle name for class %@, bundle:%@",NSStringFromClass(aClass), bundle);
                NSString *headerPath = [bundle.bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Headers/%@.h",NSStringFromClass(aClass)]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:headerPath]) {
                    [code appendFormat:@"\n#import <%@/%@.h>",bundleName,NSStringFromClass(aClass)];
                } else {
                    [code appendFormat:@"\n#import <%@/%@.h>",bundleName,bundleName];
                }
            }
        }
    };
    
    if (objcViewRouters.count > 0) {
        [code appendString:@"\n\n#pragma mark Objc View Router\n"];
        generateCodeForImportingRouters(objcViewRouters);
    }
    if (objcViewAdapters.count > 0) {
        [code appendString:@"\n\n#pragma mark Objc View Adapter\n"];
        generateCodeForImportingRouters(objcViewAdapters);
    }
    if (objcServiceRouters.count > 0) {
        [code appendString:@"\n\n#pragma mark Objc Service Router\n"];
        generateCodeForImportingRouters(objcServiceRouters);
    }
    if (objcServiceAdapters.count > 0) {
        [code appendString:@"\n\n#pragma mark Objc Service Adapter\n"];
        generateCodeForImportingRouters(objcServiceAdapters);
    }
    
    
    return code;
}

NSString *codeForRegisteringRouters() {
    NSMutableArray<Class> *objcViewRouters = [NSMutableArray array];
    NSMutableArray<Class> *objcViewAdapters = [NSMutableArray array];
    NSMutableArray<Class> *swiftViewRouters = [NSMutableArray array];
    NSMutableArray<Class> *swiftViewAdapters = [NSMutableArray array];
    
    NSMutableArray<Class> *objcServiceRouters = [NSMutableArray array];
    NSMutableArray<Class> *objcServiceAdapters = [NSMutableArray array];
    NSMutableArray<Class> *swiftServiceRouters = [NSMutableArray array];
    NSMutableArray<Class> *swiftServiceAdapters = [NSMutableArray array];
    
    ZIKRouter_enumerateClassList(^(__unsafe_unretained Class aClass) {
#if __has_include("ZIKViewRouter.h")
        if ([ZIKViewRouteRegistry isRegisterableRouterClass:aClass]) {
            if ([aClass isAdapter]) {
                if ([NSStringFromClass(aClass) zix_containsString:@"."]) {
                    [swiftViewAdapters addObject:aClass];
                } else {
                    [objcViewAdapters addObject:aClass];
                }
            } else {
                if ([NSStringFromClass(aClass) zix_containsString:@"."]) {
                    [swiftViewRouters addObject:aClass];
                } else {
                    [objcViewRouters addObject:aClass];
                }
            }
        } else
#endif
        if ([ZIKServiceRouteRegistry isRegisterableRouterClass:aClass]) {
            if ([aClass isAdapter]) {
                if ([NSStringFromClass(aClass) zix_containsString:@"."]) {
                    [swiftServiceAdapters addObject:aClass];
                } else {
                    [objcServiceAdapters addObject:aClass];
                }
            } else {
                if ([NSStringFromClass(aClass) zix_containsString:@"."]) {
                    [swiftServiceRouters addObject:aClass];
                } else {
                    [objcServiceRouters addObject:aClass];
                }
            }
        }
    });
    
    NSMutableString *code = [NSMutableString string];
    
    void(^generateCodeForObjcRouters)(NSArray<Class> *) = ^(NSArray<Class> *routers) {
        for (Class aClass in routers) {
            [code appendFormat:@"[%@ registerRoutableDestination];\n",NSStringFromClass(aClass)];
        }
    };
    void(^generateCodeForSwiftRouters)(NSArray<Class> *) = ^(NSArray<Class> *routers) {
        for (Class aClass in routers) {
            [code appendFormat:@"%@.registerRoutableDestination()\n",NSStringFromClass(aClass)];
        }
    };
    
    if (objcViewRouters.count > 0) {
        [code appendString:@"\n// Objc view routers\n"];
        generateCodeForObjcRouters(objcViewRouters);
    }
    if (objcViewAdapters.count > 0) {
        [code appendString:@"\n// Objc view adapters\n"];
        generateCodeForObjcRouters(objcViewAdapters);
    }
    if (swiftViewRouters.count > 0) {
        [code appendString:@"\n// Swift view routers\n"];
        [code appendString:@"///Can't access swift routers, because they use generic. You have to register swift router in swift code.\n"];
        generateCodeForSwiftRouters(swiftViewRouters);
    }
    if (swiftViewAdapters.count > 0) {
        [code appendString:@"\n// Swift view adapters\n"];
        [code appendString:@"///Can't access swift adapters, because they use generic. You have to register swift router in swift code.\n"];
        generateCodeForSwiftRouters(swiftViewAdapters);
    }
    if (objcServiceRouters.count > 0) {
        [code appendString:@"\n// Objc service routers\n"];
        generateCodeForObjcRouters(objcServiceRouters);
    }
    if (objcServiceAdapters.count > 0) {
        [code appendString:@"\n// Objc service adapters\n"];
        generateCodeForObjcRouters(objcServiceAdapters);
    }
    if (swiftServiceRouters.count > 0) {
        [code appendString:@"\n// Swift service routers\n"];
        [code appendString:@"///Can't access swift routers, because they use generic. You have to register swift router in swift code.\n"];
        generateCodeForSwiftRouters(swiftServiceRouters);
    }
    if (swiftServiceAdapters.count > 0) {
        [code appendString:@"\n// Swift service adapters\n"];
        [code appendString:@"///Can't access swift adapters, because they use generic. You have to register swift router in swift code.\n"];
        generateCodeForSwiftRouters(swiftServiceAdapters);
    }
    [code appendString:@"[ZIKRouteRegistry notifyRegistrationFinished];"];
    return code;
}

#import "ZIKClassCapabilities.h"
#if __has_include("ZIKViewRouter.h")
#import "UIViewController+ZIKViewRouter.h"
#endif

void zix_checkMemoryLeak(id object, NSTimeInterval delaySecond, void(^handler)(id leakedObject)) {
    if (!object) {
        return;
    }
    if (delaySecond <= 0) {
        return;
    }
    static NSMutableDictionary<NSString *, NSString *> *_leakedObjects;
    static NSHashTable *_existingObjects;
    static dispatch_queue_t memoryLeakCheckQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _leakedObjects = [NSMutableDictionary dictionary];
        _existingObjects = [NSHashTable weakObjectsHashTable];
        memoryLeakCheckQueue = dispatch_queue_create("com.zuik.router.object_leak_check_queue", DISPATCH_QUEUE_SERIAL);
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    if ([[object class] respondsToSelector:@selector(sharedInstance)]) {
        return;
    }
#pragma clang diagnostic pop
    __weak id weakObject = object;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySecond * NSEC_PER_SEC)), memoryLeakCheckQueue, ^{
        if (_leakedObjects.count > 0) {
            // Check reclaimed objects since last checking
            NSMutableSet<NSString *> *reclaimedObjects = [NSMutableSet setWithArray:_leakedObjects.allKeys];
            [[_existingObjects setRepresentation] enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                [reclaimedObjects removeObject:[NSString stringWithFormat:@"%p", (void *)obj]];
            }];
            if (reclaimedObjects.count > 0) {
                NSMutableString *reclaimedDescription = [NSMutableString string];
                [reclaimedObjects enumerateObjectsUsingBlock:^(NSString * _Nonnull address, BOOL * _Nonnull stop) {
                    NSString *description = _leakedObjects[address];
                    _leakedObjects[address] = nil;
                    [reclaimedDescription appendFormat:@"destination(%@):%@\n", address, description];
                }];
                NSLog(@"\n\nZIKRouter memory leak checker:♻️ last leaked objects were dealloced already:\n%@\n\n", reclaimedDescription);
            }
        }
        
        if (weakObject) {
#if __has_include("ZIKViewRouter.h")
            if ([weakObject respondsToSelector:@selector(zix_routed)] && [weakObject zix_routed]) {
                return;
            }
#endif
            [_existingObjects addObject:weakObject];
            _leakedObjects[[NSString stringWithFormat:@"%p", (void *)weakObject]] = [weakObject description];
            if (handler) {
                handler(weakObject);
                return;
            }
            if ([weakObject isKindOfClass:[XXViewController class]]) {
                XXViewController *parent = [weakObject parentViewController];
                if (parent) {
                    NSLog(@"\n\nZIKRouter memory leak checker:⚠️ destination is not dealloced after removed, make sure there is no retain cycle:\n%@\nIts parentViewController: %@\nThe UIKit system may hold the object, if the view is still in view hierarchy, you can ignore this.\n\n", weakObject, parent);
                } else {
                    NSLog(@"\n\nZIKRouter memory leak checker:⚠️ destination is not dealloced after removed, make sure there is no retain cycle:\n%@\nThe UIKit system may hold the object, if the view is still in view hierarchy, you can ignore this.\n\n", weakObject);
                }
                return;
            } else if ([weakObject isKindOfClass:[XXView class]]) {
                XXView *superview = [weakObject superview];
                if (superview) {
                    NSLog(@"\n\nZIKRouter memory leak checker:⚠️ destination is not dealloced after removed, make sure there is no retain cycle:\n%@\nIts superview: %@\nThe UIKit system may hold the object, if the view is still in view hierarchy, you can ignore this.\n\n", weakObject, superview);
                } else {
                    NSLog(@"\n\nZIKRouter memory leak checker:⚠️ destination is not dealloced after removed, make sure there is no retain cycle:\n%@\nThe UIKit system may hold the object, if the view is still in view hierarchy, you can ignore this.\n\n", weakObject);
                }
                return;
            }
            NSLog(@"\n\nZIKRouter memory leak checker:⚠️ destination is not dealloced after removed, make sure there is no retain cycle:\n%@\n\n", weakObject);
        }
    });
}

#endif

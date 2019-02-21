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
        NSCAssert1([[ZIKImageSymbol symbolNameForAddress:_conformsToProtocols] zix_containsString:@"OpaqueValue"] &&
                   [[ZIKImageSymbol symbolNameForAddress:_conformsToProtocols] zix_containsString:@"TargetMetadata"] &&
                   [[ZIKImageSymbol symbolNameForAddress:_conformsToProtocols] zix_containsString:@"WitnessTable"]
                   , @"The symbol name is not matched: %@", [ZIKImageSymbol symbolNameForAddress:_conformsToProtocols]);
    });
    if (_conformsToProtocols == NULL) {
        return false;
    }
    return _conformsToProtocols(value, type, existentialType, conformances);
}

static bool _objcClassConformsToSwiftProtocolName(Class objcClass, NSString *swiftProtocolName) {
    NSCAssert1([swiftProtocolName zix_containsString:@"."], @"Invalid swift protocol name: %@", swiftProtocolName);
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
        if ([demangledName zix_containsString:@"protocol witness table for"]) {

            for (NSString *protocolName in protocolNames) {
                if ([demangledName zix_containsString:[NSString stringWithFormat:@"__ObjC.%@ : %@", containedClassName, protocolName]]) {
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
        if (type == ZIKSwiftMetadataKindMetatype || type == ZIKSwiftMetadataKindExistentialMetatype || type == ZIKSwiftMetadataKindMetatype_old || type == ZIKSwiftMetadataKindExistentialMetatype_old) {
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
        if (type == ZIKSwiftMetadataKindMetatype || type == ZIKSwiftMetadataKindExistentialMetatype || type == ZIKSwiftMetadataKindMetatype_old || type == ZIKSwiftMetadataKindExistentialMetatype_old) {
            //OpaqueValue is struct SwiftValueHeader, `Metadata *` is its first member
            targetTypeMetadata = dereferencedPointer(targetTypeOpaqueValue);
            type = (ZIKSwiftMetadataKind)dereferencedPointer(targetTypeMetadata);
        }
        //target should be swift protocol
        if (type != ZIKSwiftMetadataKindExistential && type != ZIKSwiftMetadataKindExistential_old) {
            return false;
        } else {
            //For pure objc class, can't check conformance with swift_conformsToProtocols, need to use swift type metadata of this class as sourceTypeMetadata, or just search protocol witness table for this class
            if (object_is_class(sourceType) && isSourceSwiftObjectType == NO &&
                [[NSStringFromClass(sourceType) demangledAsSwift] zix_containsString:@"."] == NO) {
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
    
    ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
#if __has_include("ZIKViewRouter.h")
        if ([ZIKViewRouteRegistry isRegisterableRouterClass:class]) {
            if ([NSStringFromClass(class) zix_containsString:@"."]) {
                return;
            }
            if ([class isAdapter]) {
                [objcViewAdapters addObject:class];
            } else {
                [objcViewRouters addObject:class];
            }
        } else
#endif
        if ([ZIKServiceRouteRegistry isRegisterableRouterClass:class]) {
            if ([NSStringFromClass(class) zix_containsString:@"."]) {
                return;
            }
            if ([class isAdapter]) {
                [objcServiceAdapters addObject:class];
            } else {
                [objcServiceRouters addObject:class];
            }
        }
    });
    
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    NSMutableString *code = [NSMutableString string];
    
    void(^generateCodeForImportingRouters)(NSArray<Class> *) = ^(NSArray<Class> *routers) {
        for (Class class in routers) {
            NSBundle *bundle = [NSBundle bundleForClass:class];
            NSCAssert1(bundle, @"Failed to get bundle for class %@",NSStringFromClass(class));
            if ([bundle isEqual:mainBundle]) {
                [code appendFormat:@"\n#import \"%@.h\"",NSStringFromClass(class)];
            } else {
                NSString *bundleName = [bundle.infoDictionary objectForKey:(__bridge NSString *)kCFBundleNameKey];
                NSCAssert2(bundle, @"Failed to get bundle name for class %@, bundle:%@",NSStringFromClass(class), bundle);
                NSString *headerPath = [bundle.bundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"Headers/%@.h",NSStringFromClass(class)]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:headerPath]) {
                    [code appendFormat:@"\n#import <%@/%@.h>",bundleName,NSStringFromClass(class)];
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
    
    ZIKRouter_enumerateClassList(^(__unsafe_unretained Class class) {
#if __has_include("ZIKViewRouter.h")
        if ([ZIKViewRouteRegistry isRegisterableRouterClass:class]) {
            if ([class isAdapter]) {
                if ([NSStringFromClass(class) zix_containsString:@"."]) {
                    [swiftViewAdapters addObject:class];
                } else {
                    [objcViewAdapters addObject:class];
                }
            } else {
                if ([NSStringFromClass(class) zix_containsString:@"."]) {
                    [swiftViewRouters addObject:class];
                } else {
                    [objcViewRouters addObject:class];
                }
            }
        } else
#endif
        if ([ZIKServiceRouteRegistry isRegisterableRouterClass:class]) {
            if ([class isAdapter]) {
                if ([NSStringFromClass(class) zix_containsString:@"."]) {
                    [swiftServiceAdapters addObject:class];
                } else {
                    [objcServiceAdapters addObject:class];
                }
            } else {
                if ([NSStringFromClass(class) zix_containsString:@"."]) {
                    [swiftServiceRouters addObject:class];
                } else {
                    [objcServiceRouters addObject:class];
                }
            }
        }
    });
    
    NSMutableString *code = [NSMutableString string];
    
    void(^generateCodeForObjcRouters)(NSArray<Class> *) = ^(NSArray<Class> *routers) {
        for (Class class in routers) {
            [code appendFormat:@"[%@ registerRoutableDestination];\n",NSStringFromClass(class)];
        }
    };
    void(^generateCodeForSwiftRouters)(NSArray<Class> *) = ^(NSArray<Class> *routers) {
        for (Class class in routers) {
            [code appendFormat:@"%@.registerRoutableDestination()\n",NSStringFromClass(class)];
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

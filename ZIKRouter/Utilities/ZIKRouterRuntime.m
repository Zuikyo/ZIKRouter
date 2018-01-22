//
//  ZIKRouterRuntime.m
//  ZIKRouter
//
//  Created by zuik on 2017/9/20.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouterRuntime.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#include <mach-o/dyld.h>
#import "ZIKImageSymbol.h"

bool ZIKRouter_replaceMethodWithMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    NSCParameterAssert(originalClass);
    NSCParameterAssert(originalSelector);
    NSCParameterAssert(swizzledClass);
    NSCParameterAssert(swizzledSelector);
    NSCParameterAssert(!(originalClass == swizzledClass && originalSelector == swizzledSelector));
    NSCAssert2(class_respondsToSelector(object_getClass(originalClass), swizzledSelector) == NO, @"originalClass(%@) already exists same method name(%@) to swizzle",originalClass,NSStringFromSelector(swizzledSelector));
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    bool originIsClassMethod = false;
    if (!originalMethod) {
        originIsClassMethod = true;
        originalMethod = class_getClassMethod(originalClass, originalSelector);
        //        originalClass = objc_getMetaClass(object_getClassName(originalClass));
    }
    if (!originalMethod) {
        NSLog(@"replace failed, can't find original method:%@",NSStringFromSelector(originalSelector));
        return false;
    }
    
    if (!swizzledMethod) {
        swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    }
    if (!swizzledMethod) {
        NSLog(@"replace failed, can't find swizzled method:%@",NSStringFromSelector(swizzledSelector));
        return false;
    }
    
    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    if (originalIMP == swizzledIMP) {//original class was already swizzled, or originalSelector's implementation is in super class but super class was already swizzled
        return true;
    }
    
    if (originIsClassMethod) {
        originalClass = objc_getMetaClass(class_getName(originalClass));
    }
    
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    if (strcmp(originalType, swizzledType) != 0) {
        NSLog(@"warning：method signature not match, please confirm！original method:%@\n signature:%s\nswizzled method:%@\nsignature:%s",NSStringFromSelector(originalSelector),originalType,NSStringFromSelector(swizzledSelector),swizzledType);
        swizzledType = originalType;
    }
    class_replaceMethod(originalClass,swizzledSelector,originalIMP,originalType);
    class_replaceMethod(originalClass,originalSelector,swizzledIMP,swizzledType);
    return true;
}

bool ZIKRouter_replaceMethodWithMethodType(Class originalClass, SEL originalSelector, bool originIsClassMethod, Class swizzledClass, SEL swizzledSelector, bool swizzledIsClassMethod) {
    NSCParameterAssert(originalClass);
    NSCParameterAssert(originalSelector);
    NSCParameterAssert(swizzledClass);
    NSCParameterAssert(swizzledSelector);
    NSCParameterAssert(!(originalClass == swizzledClass && originalSelector == swizzledSelector));
    NSCAssert2((swizzledIsClassMethod == NO && [originalClass instancesRespondToSelector:swizzledSelector] == NO) ||
               (swizzledIsClassMethod == YES && class_respondsToSelector(object_getClass(originalClass), swizzledSelector) == NO), @"originalClass(%@) already exists same method name(%@) to swizzle",originalClass,NSStringFromSelector(swizzledSelector));
    Method originalMethod;
    Method swizzledMethod;
    if (originIsClassMethod) {
        originalMethod = class_getClassMethod(originalClass, originalSelector);
    } else {
        originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    }
    if (swizzledIsClassMethod) {
        swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    } else {
        swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    }
    if (!originalMethod) {
        NSLog(@"replace failed, can't find original method:%@",NSStringFromSelector(originalSelector));
        return false;
    }
    if (!swizzledMethod) {
        NSLog(@"replace failed, can't find swizzled method:%@",NSStringFromSelector(swizzledSelector));
        return false;
    }
    
    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    if (originalIMP == swizzledIMP) {//original class was already swizzled, or originalSelector's implementation is in super class but super class was already swizzled
        return true;
    }
    if (originIsClassMethod) {
        originalClass = objc_getMetaClass(class_getName(originalClass));
    }
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    if (strcmp(originalType, swizzledType) != 0) {
        NSLog(@"warning：method signature not match, please confirm！original method:%@\n signature:%s\nswizzled method:%@\nsignature:%s",NSStringFromSelector(originalSelector),originalType,NSStringFromSelector(swizzledSelector),swizzledType);
        swizzledType = originalType;
    }
    class_replaceMethod(originalClass,swizzledSelector,originalIMP,originalType);
    class_replaceMethod(originalClass,originalSelector,swizzledIMP,swizzledType);
    return true;
}

IMP ZIKRouter_replaceMethodWithMethodAndGetOriginalImp(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    NSCParameterAssert(originalClass);
    NSCParameterAssert(originalSelector);
    NSCParameterAssert(swizzledClass);
    NSCParameterAssert(swizzledSelector);
    NSCParameterAssert(!(originalClass == swizzledClass && originalSelector == swizzledSelector));
    NSCAssert2(class_respondsToSelector(object_getClass(originalClass), swizzledSelector) == NO, @"originalClass(%@) already exists same method name(%@) to swizzle",originalClass,NSStringFromSelector(swizzledSelector));
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    bool originIsClassMethod = false;
    if (!originalMethod) {
        originIsClassMethod = true;
        originalMethod = class_getClassMethod(originalClass, originalSelector);
        //        originalClass = objc_getMetaClass(object_getClassName(originalClass));
    }
    if (!originalMethod) {
        NSLog(@"replace failed, can't find original method:%@",NSStringFromSelector(originalSelector));
        return NULL;
    }
    
    if (!swizzledMethod) {
        swizzledMethod = class_getClassMethod(swizzledClass, swizzledSelector);
    }
    if (!swizzledMethod) {
        NSLog(@"replace failed, can't find swizzled method:%@",NSStringFromSelector(swizzledSelector));
        return NULL;
    }
    
    IMP originalIMP = method_getImplementation(originalMethod);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    if (originalIMP == swizzledIMP) {//original class was already swizzled, or originalSelector's implementation is in super class but super class was already swizzled
        return NULL;
    }
    if (originIsClassMethod) {
        originalClass = objc_getMetaClass(class_getName(originalClass));
    }
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    if (strcmp(originalType, swizzledType) != 0) {
        NSLog(@"warning：method signature not match, please confirm！original method:%@\n signature:%s\nswizzled method:%@\nsignature:%s",NSStringFromSelector(originalSelector),originalType,NSStringFromSelector(swizzledSelector),swizzledType);
        swizzledType = originalType;
    }
    BOOL success = class_addMethod(originalClass, originalSelector, swizzledIMP, swizzledType);
    if (success) {
        //method is in originalClass's superclass chain
        success = class_addMethod(originalClass, swizzledSelector, originalIMP, originalType);
        NSCAssert(success, @"swizzledSelector shouldn't exist in original class before hook");
        return NULL;
    } else {
        //method is in originalClass
        success = class_addMethod(originalClass, swizzledSelector, originalIMP, originalType);
        NSCAssert(success, @"swizzledSelector shouldn't exist in original class before hook");
        method_setImplementation(originalMethod, swizzledIMP);
        return originalIMP;
    }
}

void ZIKRouter_enumerateClassList(void(^handler)(Class aClass)) {
    NSCParameterAssert(handler);
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    for (NSInteger i = 0; i < numClasses; i++) {
        Class aClass = classes[i];
        if (aClass) {
            handler(aClass);
        }
    }
    
    free(classes);
}

void ZIKRouter_enumerateProtocolList(void(^handler)(Protocol *protocol)) {
    NSCParameterAssert(handler);
    unsigned int outCount;
    Protocol *__unsafe_unretained *protocols = objc_copyProtocolList(&outCount);
    for (int i = 0; i < outCount; i++) {
        Protocol *protocol = protocols[i];
        if (protocol) {
            handler(protocol);
        }
    }
    free(protocols);
}

bool ZIKRouter_classIsSubclassOfClass(Class aClass, Class parentClass) {
    NSCParameterAssert(aClass);
    NSCParameterAssert(parentClass);
    Class superClass = aClass;
    do {
        superClass = class_getSuperclass(superClass);
    } while (superClass != parentClass && superClass);
    
    if (superClass == nil) {
        return false;
    }
    return true;
}

bool ZIKRouter_classIsCustomClass(Class aClass) {
    NSCParameterAssert(aClass);
    if (!aClass) {
        return false;
    }
    static NSString *mainBundlePath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainBundlePath = [[NSBundle mainBundle] bundlePath];
    });
    if ([[[NSBundle bundleForClass:aClass] bundlePath] isEqualToString:mainBundlePath]) {
        return true;
    }
    return false;
}

bool ZIKRouter_classSelfImplementingMethod(Class aClass, SEL method, bool isClassMethod) {
    NSCParameterAssert(aClass);
    NSCParameterAssert(method);
    if (!aClass) {
        return false;
    }
    if (!method) {
        return false;
    }
    Method selfMethod;
    if (!isClassMethod) {
        selfMethod = class_getInstanceMethod(aClass, method);
    } else {
        selfMethod = class_getClassMethod(aClass, method);
    }
    if (!selfMethod) {
        return false;
    }
    Class superClass = class_getSuperclass(aClass);
    if (!superClass) {
        return true;
    }
    Method superMethod;
    if (!isClassMethod) {
        superMethod = class_getInstanceMethod(superClass, method);
    } else {
        superMethod = class_getClassMethod(superClass, method);
    }
    if (!superMethod) {
        return true;
    }
    return method_getImplementation(selfMethod) != method_getImplementation(superMethod);
}

bool ZIKRouter_isObjcProtocol(id protocol) {
    static Class ProtocolClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ProtocolClass = NSClassFromString(@"Protocol");
    });
    return [protocol isKindOfClass:ProtocolClass];
}

#if DEBUG
/**
 Check whether a type conforms to the given protocol. Use private C++ function inside libswiftCore.dylib:
 `bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)`.

 @return The function pointer of _conformsToProtocols().
 */
static bool(*swift_conformsToProtocols())(void *, void *, void *, void *) {
    static void *_conformsToProtocols = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *libswiftCorePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Frameworks/libswiftCore.dylib"];
        long address;
        NSLog(@"\nZIKRouter:: _swift_typeConformsToProtocol():\nStart searching function pointer for\n`bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)` in libswiftCore.dylib to validate swift type.\n");
        
        ZIKImageRef libswiftCoreImage = [ZIKImageSymbol imageByName:libswiftCorePath.UTF8String];
        _conformsToProtocols = [ZIKImageSymbol findSymbolInImage:libswiftCoreImage name:"_conformsToProtocols" matchAsSubstring:YES];
        NSCAssert1([[ZIKImageSymbol symbolNameForAddress:_conformsToProtocols] containsString:@"OpaqueValue"] &&
                  [[ZIKImageSymbol symbolNameForAddress:_conformsToProtocols] containsString:@"ExistentialTypeMetadata"] &&
                  [[ZIKImageSymbol symbolNameForAddress:_conformsToProtocols] containsString:@"WitnessTable"]
                  , @"The symbol name is not matched: %@", [ZIKImageSymbol symbolNameForAddress:_conformsToProtocols]);
        
        address = (long)_conformsToProtocols;
        NSLog(@"\n✅ZIKRouter: function pointer address 0x%lx is found for `_conformsToProtocols`.\n",address);
    });
    
    return (bool(*)(void *, void *, void *, void *))_conformsToProtocols;
}

static void *dereferencedPointer(void *pointer) {
    void **deref = pointer;
    return *deref;
}

static BOOL isObjectClassType(id object) {
    return object == [object class];
}
#endif

bool _swift_typeIsTargetType(id sourceType, id targetType) {
#if DEBUG
    static NSString *_SwiftValueString;
    static NSString *SwiftObjectString;
    static NSString *_swiftValueString;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //Split private API name, in case you use them in release mode.
        NSString *underline = @"_";
        NSString *Swift = @"Swift";
        NSString *swift = @"swift";
        NSString *Object = @"Object";
        NSString *Value = @"Value";
        _SwiftValueString = [NSString stringWithFormat:@"%@%@%@",underline,Swift,Value];
        SwiftObjectString = [NSString stringWithFormat:@"%@%@",Swift,Object];
        _swiftValueString = [NSString stringWithFormat:@"%@%@%@",underline,swift,Value];
    });
    Class _SwiftValueClass = NSClassFromString(_SwiftValueString);
    Class SwiftObjectClass = NSClassFromString(SwiftObjectString);
    
    BOOL isSourceSwiftObjectType = [sourceType isKindOfClass:SwiftObjectClass];
    BOOL isTargetSwiftObjectType = [targetType isKindOfClass:SwiftObjectClass];
    BOOL isSourceSwiftType = isSourceSwiftObjectType || [sourceType isKindOfClass:_SwiftValueClass];
    BOOL isTargetSwiftType = isTargetSwiftObjectType || [targetType isKindOfClass:_SwiftValueClass];
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
    NSCParameterAssert(isSourceSwiftType || [sourceType isKindOfClass:[NSObject class]]);
    if (!isSourceSwiftType && !isTargetSwiftType) {
        return class_conformsToProtocol([sourceType class], targetType);
    }
    if (isSourceSwiftObjectType) {
        if (!isObjectClassType(sourceType)) {
            NSCAssert(NO, @"This function only accept type parameter, not instance parameter.");
            return false;
        }
    }
    if (isTargetSwiftObjectType) {
        if (!isObjectClassType(targetType)) {
            NSCAssert(NO, @"This function only accept type parameter, not instance parameter.");
            return false;
        }
    }
    if (isSourceSwiftObjectType && isTargetSwiftObjectType) {
        return ZIKRouter_classIsSubclassOfClass(sourceType, targetType) || [sourceType isKindOfClass:targetType] || sourceType == targetType;
    }
    
    bool (*_conformsToProtocols)(void *, void *, void *, void *) = swift_conformsToProtocols();
    if (_conformsToProtocols == NULL) {
        return false;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    void* sourceTypeOpaqueValue;
    void* sourceTypeMetadata;
    if ([sourceType isKindOfClass:SwiftObjectClass]) {
        //swift class or swift object
        sourceTypeMetadata = (__bridge void *)(sourceType);
        sourceTypeOpaqueValue = (__bridge void *)(sourceType);
    } else if ([sourceType isKindOfClass:_SwiftValueClass]) {
        //swift struct or swift enum or swift protocol
        NSCAssert2([sourceType respondsToSelector:NSSelectorFromString(_swiftValueString)], @"Swift value(%@) doesn't have method(%@), the API may be changed in libswiftCore.dylib.",sourceType,_swiftValueString);
        sourceTypeOpaqueValue = (__bridge void *)[sourceType performSelector:NSSelectorFromString(_swiftValueString)];
        sourceTypeMetadata = dereferencedPointer(sourceTypeOpaqueValue);
    } else {
        //objc class or objc protocol
        sourceTypeMetadata = (__bridge void *)(sourceType);
        sourceTypeOpaqueValue = (__bridge void *)(sourceType);
    }
    
    void* targetTypeOpaqueValue;
    void* targetTypeMetadata;
    if ([targetType isKindOfClass:_SwiftValueClass]) {
        //swift struct or swift enum or swift protocol
        NSCAssert2([targetType respondsToSelector:NSSelectorFromString(_swiftValueString)], @"Swift value(%@) doesn't have method(%@), the API may be changed in libswiftCore.dylib.",targetType,_swiftValueString);
        targetTypeOpaqueValue = (__bridge void *)[targetType performSelector:NSSelectorFromString(_swiftValueString)];
        targetTypeMetadata = dereferencedPointer(targetTypeOpaqueValue);
    } else {
        //objc protocol
        targetTypeMetadata = (__bridge void *)(targetType);
        targetTypeOpaqueValue = (__bridge void *)(targetType);
    }
#pragma clang diagnostic pop
    bool result = _conformsToProtocols(sourceTypeOpaqueValue, sourceTypeMetadata, targetTypeMetadata, NULL);
    return result;
#else
    return false;
#endif
}

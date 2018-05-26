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
    NSString *bundlePath = [[NSBundle bundleForClass:aClass] bundlePath];
    if ([bundlePath containsString:@"System/Library/"]) {
        return false;
    }
    if ([bundlePath containsString:@"usr/"]) {
        return false;
    }
    return true;
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
        ProtocolClass = [(id)@protocol(NSObject) class];
    });
    return [protocol isKindOfClass:ProtocolClass];
}

Protocol *_Nullable ZIKRouter_objcProtocol(id protocol) {
    if (ZIKRouter_isObjcProtocol(protocol)) {
        return (Protocol *)protocol;
    }
    return nil;
}

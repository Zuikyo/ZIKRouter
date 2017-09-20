//
//  ZIKRouterRuntimeHelper.m
//  ZIKRouter
//
//  Created by zuik on 2017/9/20.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "ZIKRouterRuntimeHelper.h"
#import <objc/runtime.h>

bool ZIKRouter_replaceMethodWithMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
    NSCParameterAssert(originalClass);
    NSCParameterAssert(originalSelector);
    NSCParameterAssert(swizzledClass);
    NSCParameterAssert(swizzledSelector);
    NSCParameterAssert(!(originalClass == swizzledClass && originalSelector == swizzledSelector));
    NSCAssert2([originalClass respondsToSelector:swizzledSelector] == NO, @"originalClass(%@) already exists same method name(%@) to swizzle",originalClass,NSStringFromSelector(swizzledSelector));
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
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    int cmpResult = strcmp(originalType, swizzledType);
    if (cmpResult != 0) {
        NSLog(@"warning：method signature not match, please confirm！original method:%@\n signature:%s\nswizzled method:%@\nsignature:%s",NSStringFromSelector(originalSelector),originalType,NSStringFromSelector(swizzledSelector),swizzledType);
        swizzledType = originalType;
    }
    if (originalIMP == swizzledIMP) {//original class was already swizzled, or originalSelector's implementation is in super class but super class was already swizzled
        return true;
    }
    if (originIsClassMethod) {
        originalClass = objc_getMetaClass(class_getName(originalClass));
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
               (swizzledIsClassMethod == YES && [originalClass respondsToSelector:swizzledSelector] == NO), @"originalClass(%@) already exists same method name(%@) to swizzle",originalClass,NSStringFromSelector(swizzledSelector));
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
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    int cmpResult = strcmp(originalType, swizzledType);
    if (cmpResult != 0) {
        NSLog(@"warning：method signature not match, please confirm！original method:%@\n signature:%s\nswizzled method:%@\nsignature:%s",NSStringFromSelector(originalSelector),originalType,NSStringFromSelector(swizzledSelector),swizzledType);
        swizzledType = originalType;
    }
    if (originalIMP == swizzledIMP) {//original class was already swizzled, or originalSelector's implementation is in super class but super class was already swizzled
        return true;
    }
    if (originIsClassMethod) {
        originalClass = objc_getMetaClass(class_getName(originalClass));
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
    NSCAssert2([originalClass respondsToSelector:swizzledSelector] == NO, @"originalClass(%@) already exists same method name(%@) to swizzle",originalClass,NSStringFromSelector(swizzledSelector));
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
    const char *originalType = method_getTypeEncoding(originalMethod);
    const char *swizzledType = method_getTypeEncoding(swizzledMethod);
    int cmpResult = strcmp(originalType, swizzledType);
    if (cmpResult != 0) {
        NSLog(@"warning：method signature not match, please confirm！original method:%@\n signature:%s\nswizzled method:%@\nsignature:%s",NSStringFromSelector(originalSelector),originalType,NSStringFromSelector(swizzledSelector),swizzledType);
        swizzledType = originalType;
    }
    if (originalIMP == swizzledIMP) {//original class was already swizzled, or originalSelector's implementation is in super class but super class was already swizzled
        return NULL;
    }
    if (originIsClassMethod) {
        originalClass = objc_getMetaClass(class_getName(originalClass));
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

void ZIKRouter_enumerateClassList(void(^handler)(Class class)) {
    NSCParameterAssert(handler);
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    // from http://stackoverflow.com/a/8731509/46768
    classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    for (NSInteger i = 0; i < numClasses; i++) {
        Class class = classes[i];
        handler(class);
    }
    
    free(classes);
}

void ZIKRouter_enumerateProtocolList(void(^handler)(Protocol *protocol)) {
    NSCParameterAssert(handler);
    unsigned int outCount;
    Protocol *__unsafe_unretained *protocols = objc_copyProtocolList(&outCount);
    for (int i = 0; i < outCount; i++) {
        Protocol *protocol = protocols[i];
        handler(protocol);
    }
    free(protocols);
}

bool ZIKRouter_classIsSubclassOfClass(Class class, Class parentClass) {
    NSCParameterAssert(class);
    NSCParameterAssert(parentClass);
    Class superClass = class;
    do {
        superClass = class_getSuperclass(superClass);
    } while (superClass && superClass != parentClass);
    
    if (superClass == nil) {
        return false;
    }
    return true;
}

NSArray *ZIKRouter_subclassesComformToProtocol(NSArray<Class> *classes, Protocol *protocol) {
    NSCParameterAssert(classes);
    NSCParameterAssert(protocol);
    NSMutableArray *result = [NSMutableArray array];
    for (Class class in classes) {
        if (class_conformsToProtocol(class, protocol)) {
            [result addObject:class];
        }
    }
    return result;
}

bool ZIKRouter_classIsCustomClass(Class class) {
    NSCParameterAssert(class);
    if (!class) {
        return false;
    }
    static NSString *mainBundlePath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mainBundlePath = [[NSBundle mainBundle] bundlePath];
    });
    if ([[[NSBundle bundleForClass:class] bundlePath] isEqualToString:mainBundlePath]) {
        return true;
    }
    return false;
}

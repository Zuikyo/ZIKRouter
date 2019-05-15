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

bool zix_replaceMethodWithMethod(Class originalClass, SEL originalSelector, Class swizzledClass, SEL swizzledSelector) {
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

bool zix_replaceMethodWithMethodType(Class originalClass, SEL originalSelector, bool originIsClassMethod, Class swizzledClass, SEL swizzledSelector, bool swizzledIsClassMethod) {
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

void zix_enumerateClassList(void(^handler)(Class aClass)) {
    NSCParameterAssert(handler);
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    for (NSInteger i = 0; i < numClasses; i++) {
        Class aClass = classes[i];
        if (aClass) {
#if DEBUG
            // If `Zombie Objects` in Xcode Diagnostics is enabled, the last two classes may be not readable, there will be EXC_BAD_ACCESS. Disabling `Zombie Objects` can resolve it.
            Class superClass = class_getSuperclass(aClass);
            if ((intptr_t)superClass > 0x5000000000000000) {
                continue;
            }
#endif
            handler(aClass);
        } else {
            break;
        }
    }
    
    free(classes);
}

void zix_enumerateProtocolList(void(^handler)(Protocol *protocol)) {
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

bool zix_classIsSubclassOfClass(Class aClass, Class parentClass) {
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

bool zix_classIsCustomClass(Class aClass) {
    NSCParameterAssert(aClass);
    if (!aClass) {
        return false;
    }
    NSString *bundlePath = [[NSBundle bundleForClass:aClass] bundlePath];
    if ([bundlePath rangeOfString:@"/System/Library/"].length != 0) {
        return false;
    }
    if ([bundlePath rangeOfString:@"/usr/"].length != 0) {
        return false;
    }
    return true;
}

bool zix_classSelfImplementingMethod(Class aClass, SEL method, bool isClassMethod) {
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

bool zix_isObjcProtocol(id protocol) {
    static Class ProtocolClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ProtocolClass = [(id)@protocol(NSObject) class];
    });
    return [protocol isKindOfClass:ProtocolClass];
}

bool zix_protocolConformsToProtocol(Protocol *protocol, Protocol *parentProtocol) {
    unsigned int count;
    Protocol * __unsafe_unretained _Nonnull *list = protocol_copyProtocolList(protocol, &count);
    if (list == NULL) {
        return NO;
    }
    BOOL result = NO;
    for (int i = 0; i < count; i++) {
        Protocol *parent = list[i];
        if (parent == parentProtocol) {
            result = YES;
            break;
        } else if (zix_protocolConformsToProtocol(parent, parentProtocol)) {
            result = YES;
            break;
        }
    }
    free(list);
    return result;
}

Protocol *_Nullable zix_objcProtocol(id protocol) {
    if (zix_isObjcProtocol(protocol)) {
        return (Protocol *)protocol;
    }
    return nil;
}

#import <mach/mach.h>

#if !__LP64__

// class is a Swift class
#define FAST_IS_SWIFT         (1UL<<0)
// data pointer
#define FAST_DATA_MASK        0xfffffffcUL

#elif 1
// Leaks-compatible version that steals low bits only.

// class is a Swift class
#define FAST_IS_SWIFT           (1UL<<0)
// data pointer
#define FAST_DATA_MASK          0x00007ffffffffff8UL

#else
// Leaks-incompatible version that steals lots of bits.

// class is a Swift class
#define FAST_IS_SWIFT           (1UL<<0)
// data pointer
#define FAST_DATA_MASK          0x00007ffffffffff8UL

#endif

typedef struct class_ro_t {
    const uint32_t flags;
    const uint32_t instanceStart;
    const uint32_t instanceSize;
#ifdef __LP64__
    const uint32_t reserved;
#endif
    
    const uint8_t * ivarLayout;
    
    const char * name;
    const void * baseMethodList;
    const void * baseProtocols;
    const void * ivars;
    
    const uint8_t * weakIvarLayout;
    const void * baseProperties;
} class_ro_t;

typedef struct class_rw_t {
    const uint32_t flags;
    const uint32_t version;
    
    const class_ro_t *ro;
    
    const void *methods;
    const void *properties;
    const void *protocols;
    
    const Class firstSubclass;
    const Class nextSiblingClass;
    
    const char *demangledName;
} class_rw_t;

typedef struct objc_cache *Cache;

typedef struct class_t {
    const struct class_t *isa;
    const struct class_t *superclass;
#pragma clang diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    const Cache cache;
#pragma clang diagnostic pop
    const IMP *vtable;
    const uintptr_t data_NEVER_USE;  // class_rw_t * plus custom rr/alloc flags
} class_t;

class_rw_t *rw_of_class(class_t *cls) {
    return (class_rw_t *)(cls->data_NEVER_USE & FAST_DATA_MASK);
}

class_ro_t *ro_of_class(class_t *cls) {
    return (class_ro_t *)(cls->data_NEVER_USE & FAST_DATA_MASK);
}

#import <mach-o/getsect.h>
#include <mach-o/dyld.h>

#ifndef __LP64__
typedef struct mach_header mach_header_xx;
#else
typedef struct mach_header_64 mach_header_xx;
#endif

static void enumerateImages(void(^handler)(const mach_header_xx *mh, const char *path)) {
    if (handler == nil) {
        return;
    }
    for (uint32_t i = 0, count = _dyld_image_count(); i < count; i++) {
        handler((const mach_header_xx *)_dyld_get_image_header(i), _dyld_get_image_name(i));
    }
}

// Check that objc class layout is not changed
static BOOL canReadSuperclassOfClass(Class aClass) {
    class_t *cls = (__bridge class_t *)aClass;
    uintptr_t superClassAddr = (uintptr_t)cls + sizeof(class_t *);
    uintptr_t superClass;
    vm_size_t size;
    kern_return_t result = vm_read_overwrite(mach_task_self(), superClassAddr, sizeof(void*), (vm_address_t)&superClass, &size);
    if (result != KERN_SUCCESS) {
        // Can't read the address, objc class layout may be changed
        return NO;
    }
    return YES;
}

BOOL zix_canEnumerateClassesInImage() {
    if (canReadSuperclassOfClass([NSObject class]) == NO) {
        return NO;
    }
    NSString *mainBundlePath = [NSBundle mainBundle].executablePath;
    for (uint32_t i = 0, count = _dyld_image_count(); i < count; i++) {
        const char *path = _dyld_get_image_name(i);
        if (strcmp(path, mainBundlePath.UTF8String) == 0) {
            const mach_header_xx *mh = (const mach_header_xx *)_dyld_get_image_header(i);
#ifndef __LP64__
            const struct section *section = getsectbynamefromheader(mh, "__DATA", "__objc_classlist");
            if (section == NULL) {
                return NO;
            }
            uint32_t size = section->size;
#else
            const struct section_64 *section = getsectbynamefromheader_64(mh, "__DATA", "__objc_classlist");
            if (section == NULL) {
                return NO;
            }
            uint64_t size = section->size;
#endif
            if (size > 0) {
                char *imageBaseAddress = (char *)mh;
                Class *classReferences = (Class *)(void *)(imageBaseAddress + ((uintptr_t)section->offset&0xffffffff));
                Class firstClass = classReferences[0];
                if (canReadSuperclassOfClass(firstClass) == NO) {
                    return NO;
                }
            }
            break;
        }
    }
    return YES;
}

static void enumerateClassesInImage(const mach_header_xx *mh, void(^handler)(Class __unsafe_unretained aClass)) {
    if (handler == nil) {
        return;
    }
#ifndef __LP64__
    const struct section *section = getsectbynamefromheader(mh, "__DATA", "__objc_classlist");
    if (section == NULL) {
        return;
    }
    uint32_t size = section->size;
#else
    const struct section_64 *section = getsectbynamefromheader_64(mh, "__DATA", "__objc_classlist");
    if (section == NULL) {
        return;
    }
    uint64_t size = section->size;
#endif
    char *imageBaseAddress = (char *)mh;
    Class *classReferences = (Class *)(void *)(imageBaseAddress + ((uintptr_t)section->offset&0xffffffff));
    for (unsigned long i = 0; i < size/sizeof(void *); i++) {
        Class aClass = classReferences[i];
        if (aClass) {
            handler(aClass);
        }
    }
}

static bool classIsSubclassOfClass(class_t *cls, class_t *parentClass) {
    if (cls == NULL || parentClass == NULL) {
        return false;
    }
    const class_t *superclass = cls->superclass;
    while (superclass) {
        if (superclass == parentClass) {
            return true;
        }
        superclass = superclass->superclass;
    }
    return false;
}

void zix_enumerateClassesInMainBundleForParentClass(Class parentClass, void(^handler)(__unsafe_unretained Class aClass)) {
    if (handler == nil) {
        return;
    }
    struct class_t *parent = (__bridge struct class_t *)(parentClass);
    enumerateImages(^(const mach_header_xx *mh, const char *path) {
        if (strstr(path, "/System/Library/") != NULL ||
            strstr(path, "/usr/") != NULL ||
            strstr(path, ".dylib") != NULL) {
            return;
        }
        enumerateClassesInImage(mh, ^(__unsafe_unretained Class aClass) {
            if (classIsSubclassOfClass((__bridge class_t *)(aClass), parent)) {
                handler(aClass);
            }
        });
    });
}

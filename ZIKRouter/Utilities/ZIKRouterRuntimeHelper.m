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
#import <dlfcn.h>
#include <mach-o/dyld.h>

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

void ZIKRouter_enumerateClassList(void(^handler)(Class aClass)) {
    NSCParameterAssert(handler);
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    // from http://stackoverflow.com/a/8731509/46768
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
        handler(protocol);
    }
    free(protocols);
}

bool ZIKRouter_classIsSubclassOfClass(Class aClass, Class parentClass) {
    NSCParameterAssert(aClass);
    NSCParameterAssert(parentClass);
    Class superClass = aClass;
    do {
        superClass = class_getSuperclass(superClass);
    } while (superClass && superClass != parentClass);
    
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

bool ZIKRouter_isObjcProtocol(id protocol) {
    return [protocol isKindOfClass:NSClassFromString(@"Protocol")];
}

static long baseAddressForImage(const char *imagePath) {
    long base = NSNotFound;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t index = 0; index < imageCount; index++) {
        const char *imageName = _dyld_get_image_name(index);
        if (strstr(imageName, imagePath) != NULL) {
            base = (long)_dyld_get_image_header(index);
            break;
        }
    }
    return base;
}

/**
 Get function pointer with it's address offset in the loaded library file.
 If you pass a wrong address and there is no function at the address, there will be an assert failure.
 
 @param address The function's address offset inside the binary file.
 @param libFileName The loaded library file path of the function.
 */
 static void* funcPointerForSymbolAddress(long address, const char *libFileName) {
    NSCParameterAssert(address > 0);
    NSCParameterAssert(libFileName);
     long base = baseAddressForImage(libFileName);
    if (base == NSNotFound) {
        NSCAssert1(NO, @"Invalid library file(%s), not exist or not be loaded.",libFileName);
        return NULL;
    }
    
    void *realAddr = (void *)(base + address);
    Dl_info dlinfo;
    dladdr(realAddr, &dlinfo);
    
    if (dlinfo.dli_fname == NULL ||
        (dlinfo.dli_fname != NULL &&
         strlen(dlinfo.dli_fname) > 0 &&
         strcmp(dlinfo.dli_fname, libFileName) != 0)) {
//        NSCAssert2(NO, @"Invalid address(0x%lx) to fetch function pointer in library file(%s). Address may be too large. Remove SWIFT_CONFORMSTOPROTOCOLS_ADDRESS and let ZIKRouter auto search.",address,libFileName);
        return NULL;
    }
    if (dlinfo.dli_saddr != realAddr) {
//        NSCAssert2(NO, @"Invalid address(0x%lx) to fetch function pointer in library file(%s). Can't find any function at this address. Remove SWIFT_CONFORMSTOPROTOCOLS_ADDRESS and let ZIKRouter auto search.",address,libFileName);
        return NULL;
    }
    
    return realAddr;
}

static void fetchBaseAddressForImage(const char *libFileName, long *baseAddress, long *endAddress) {
    long base = NSNotFound;
    long nextBase = NSNotFound;
    uint32_t imageCount = _dyld_image_count();
    NSMutableArray<NSNumber *> *baseAddressArray = [NSMutableArray array];
    for (uint32_t index = 0; index < imageCount; index++) {
        const char *imageName = _dyld_get_image_name(index);
        const struct mach_header *header = _dyld_get_image_header(index);
        [baseAddressArray addObject:@((long)header)];
        if (base == NSNotFound && strstr(imageName, libFileName) != NULL) {
            base = (long)header;
        }
    }
    if (base == NSNotFound) {
        NSCAssert1(NO, @"Invalid library file(%s), not exist or not be loaded.",libFileName);
        return;
    }
    [baseAddressArray sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    NSInteger indexOfTarget = [baseAddressArray indexOfObject:@(base)];
    if (indexOfTarget != NSNotFound && indexOfTarget < baseAddressArray.count - 1) {
        nextBase = [baseAddressArray[indexOfTarget + 1] longValue];
    } else {
        nextBase = base + (base - [baseAddressArray[indexOfTarget - 1] longValue]);
    }
    if (baseAddress) {
        *baseAddress = base;
    }
    if (endAddress) {
        *endAddress = nextBase;
    }
}

void asyncFuzzySearchFunctionPointerBySymbol(const char *libFileName, const char *fuzzyFunctionSymbol, void(^completion)(void *functionPointer)) {
    NSCParameterAssert(libFileName);
    NSCParameterAssert(fuzzyFunctionSymbol);
    __block void *foundAddress = 0;
    long beginAddress;
    long endAddress;
    fetchBaseAddressForImage(libFileName, &beginAddress, &endAddress);
    if (beginAddress == NSNotFound || endAddress == NSNotFound) {
        return;
    }
    long difference = (endAddress - beginAddress) / 20;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    for (long start = beginAddress; start < endAddress; start += difference) {
        [queue addOperationWithBlock:^{
            Dl_info dlinfo;
            long end = start + difference;
            for (long addr = end; addr > start;) {
                BOOL stop = NO;
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                if (foundAddress != 0) {
                    stop = YES;
                }
                dispatch_semaphore_signal(semaphore);
                if (stop) {
                    break;
                }
                dladdr((void *)addr, &dlinfo);
                const char *symbol = dlinfo.dli_sname;
                if (dlinfo.dli_fbase != NULL && (symbol != NULL) && (symbol[0] != '\0')) {
                    if (strstr(symbol, fuzzyFunctionSymbol) == NULL) {
                        addr -= 0x8;
                        if (addr > (long)dlinfo.dli_saddr) {
                            addr = (long)dlinfo.dli_saddr - 0x8;
                        }
                        continue;
                    }
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                    if (foundAddress == 0) {
                        foundAddress = dlinfo.dli_saddr;
                        if (completion) {
                            completion(foundAddress);
                        }
                        [queue cancelAllOperations];
                    }
                    dispatch_semaphore_signal(semaphore);
                    break;
                } else {
                    addr -= 0x8;
                    if (addr > (long)dlinfo.dli_saddr) {
                        addr = (long)dlinfo.dli_saddr - 0x8;
                    }
                }
            }
            if (queue.operationCount == 1 && foundAddress == 0 && completion) {
                completion(NULL);
            }
        }];
    }
}

void asyncSearchFunctionPointerBySymbol(const char *libFileName, const char *fuzzyFunctionSymbol, void(^completion)(void *functionPointer)) {
    NSCParameterAssert(libFileName);
    NSCParameterAssert(fuzzyFunctionSymbol);
    __block void *foundAddress = 0;
    long beginAddress;
    long endAddress;
    fetchBaseAddressForImage(libFileName, &beginAddress, &endAddress);
    if (beginAddress == NSNotFound || endAddress == NSNotFound) {
        return;
    }
    long difference = (endAddress - beginAddress) / 20;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    for (long start = beginAddress; start < endAddress; start += difference) {
        [queue addOperationWithBlock:^{
            Dl_info dlinfo;
            long end = start + difference;
            for (long addr = end; addr > start;) {
                BOOL stop = NO;
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                if (foundAddress != 0) {
                    stop = YES;
                }
                dispatch_semaphore_signal(semaphore);
                if (stop) {
                    break;
                }
                dladdr((void *)addr, &dlinfo);
                const char *symbol = dlinfo.dli_sname;
                if (dlinfo.dli_fbase != NULL && (symbol != NULL) && (symbol[0] != '\0')) {
                    if (strcmp(symbol, fuzzyFunctionSymbol) != 0) {
                        addr -= 0x8;
                        if (addr > (long)dlinfo.dli_saddr) {
                            addr = (long)dlinfo.dli_saddr - 0x8;
                        }
                        continue;
                    }
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                    if (foundAddress == 0) {
                        foundAddress = dlinfo.dli_saddr;
                        if (completion) {
                            completion(foundAddress);
                        }
                        [queue cancelAllOperations];
                    }
                    dispatch_semaphore_signal(semaphore);
                    break;
                } else {
                    addr -= 0x8;
                    if (addr > (long)dlinfo.dli_saddr) {
                        addr = (long)dlinfo.dli_saddr - 0x8;
                    }
                }
            }
            if (queue.operationCount == 1 && foundAddress == 0 && completion) {
                completion(NULL);
            }
        }];
    }
}

void* fuzzySearchFunctionPointerBySymbol(const char *libFileName, const char *fuzzyFunctionSymbol) {
    NSCParameterAssert(libFileName);
    NSCParameterAssert(fuzzyFunctionSymbol);
    __block void *foundAddress = 0;
    long beginAddress;
    long endAddress;
    fetchBaseAddressForImage(libFileName, &beginAddress, &endAddress);
    if (beginAddress == NSNotFound || endAddress == NSNotFound) {
        return NULL;
    }
    Dl_info dlinfo;
    for (long addr = endAddress; addr > beginAddress;) {
        dladdr((void *)addr, &dlinfo);
        const char *symbol = dlinfo.dli_sname;
        if (dlinfo.dli_fbase != NULL && (symbol != NULL) && (symbol[0] != '\0')) {
            if (strstr(symbol, fuzzyFunctionSymbol) == NULL) {
                addr -= 0x8;
                if (addr > (long)dlinfo.dli_saddr) {
                    addr = (long)dlinfo.dli_saddr - 0x8;
                }
                continue;
            }
            foundAddress = dlinfo.dli_saddr;
            break;
        } else {
            addr -= 0x8;
            if (addr > (long)dlinfo.dli_saddr) {
                addr = (long)dlinfo.dli_saddr - 0x8;
            }
        }
    }
    
    return foundAddress;
}

void* searchFunctionPointerBySymbol(const char *libFileName, const char *functionSymbol) {
    NSCParameterAssert(libFileName);
    NSCParameterAssert(functionSymbol);
    __block void *foundAddress = 0;
    long beginAddress;
    long endAddress;
    fetchBaseAddressForImage(libFileName, &beginAddress, &endAddress);
    if (beginAddress == NSNotFound || endAddress == NSNotFound) {
        return NULL;
    }
    Dl_info dlinfo;
    for (long addr = endAddress; addr > beginAddress;) {
        dladdr((void *)addr, &dlinfo);
        const char *symbol = dlinfo.dli_sname;
        if (dlinfo.dli_fbase != NULL && (symbol != NULL) && (symbol[0] != '\0')) {
            
            if (strstr(symbol, functionSymbol) == NULL) {
                addr -= 0x8;
                if (addr > (long)dlinfo.dli_saddr) {
                    addr = (long)dlinfo.dli_saddr - 0x8;
                }
                continue;
            }
            foundAddress = dlinfo.dli_saddr;
            break;
        } else {
            addr -= 0x8;
            if (addr > (long)dlinfo.dli_saddr) {
                addr = (long)dlinfo.dli_saddr - 0x8;
            }
        }
    }
    return foundAddress;
}

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
        NSString *addressString = [[[NSProcessInfo processInfo] environment] objectForKey:@"SWIFT_CONFORMSTOPROTOCOLS_ADDRESS"];
        long address;
        if (addressString == nil) {
            NSLog(@"\n⏳⏳⏳⏳⏳⏳⏳⏳\nZIKRouter:: _swift_typeConformsToProtocol():\nEnvironment variable SWIFT_CONFORMSTOPROTOCOLS_ADDRESS was not found.\nStart searching function pointer for\n`bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)` in libswiftCore.dylib to validate swift type.\nThis may costs 0.8 second...\n");
            _conformsToProtocols = fuzzySearchFunctionPointerBySymbol(libswiftCorePath.UTF8String, "_conformsToProtocols");
            address = (long)_conformsToProtocols;
            NSLog(@"\n✅ZIKRouter: function pointer 0x%lx is found for `_conformsToProtocols`.\nIf the searching cost too many times, set 0x%lx as environment variable SWIFT_CONFORMSTOPROTOCOLS_ADDRESS to avoid search function pointer again for later run.\n\n",address,address - baseAddressForImage(libswiftCorePath.UTF8String));
        } else {
            NSCAssert([addressString hasPrefix:@"0x"], @"Environment variable (SWIFT_CONFORMSTOPROTOCOLS_ADDRESS) should be a hex number prefixed with 0x");
            address = strtol(addressString.UTF8String, NULL, 0);
            _conformsToProtocols = funcPointerForSymbolAddress(address,libswiftCorePath.UTF8String);
            if (_conformsToProtocols == NULL) {
                addressString = [[[NSProcessInfo processInfo] environment] objectForKey:@"SWIFT_CONFORMSTOPROTOCOLS_ADDRESS_ARMV7S"];
                if (addressString != nil) {
                    NSCAssert([addressString hasPrefix:@"0x"], @"Environment variable (SWIFT_CONFORMSTOPROTOCOLS_ADDRESS_ARMV7S) should be a hex number prefixed with 0x");
                    address = strtol(addressString.UTF8String, NULL, 0);
                    _conformsToProtocols = funcPointerForSymbolAddress(address,libswiftCorePath.UTF8String);
                }
            } else {
                Dl_info dlinfo;
                dladdr(_conformsToProtocols, &dlinfo);
                if (dlinfo.dli_sname == NULL || strstr(dlinfo.dli_sname,"_conformsToProtocols") == NULL) {
                    _conformsToProtocols = NULL;
                }
            }
            if (_conformsToProtocols == NULL) {
                addressString = [[[NSProcessInfo processInfo] environment] objectForKey:@"SWIFT_CONFORMSTOPROTOCOLS_ADDRESS_ARMV7"];
                if (addressString != nil) {
                    NSCAssert([addressString hasPrefix:@"0x"], @"Environment variable (SWIFT_CONFORMSTOPROTOCOLS_ADDRESS_ARMV7) should be a hex number prefixed with 0x");
                    address = strtol(addressString.UTF8String, NULL, 0);
                    _conformsToProtocols = funcPointerForSymbolAddress(address,libswiftCorePath.UTF8String);
                }
            }
            if (_conformsToProtocols == NULL) {
                NSCAssert(NO, @"Function pointer for `_conformsToProtocols` not found. If you set SWIFT_CONFORMSTOPROTOCOLS_ADDRESS, it's value is invalid. Remove SWIFT_CONFORMSTOPROTOCOLS_ADDRESS and let ZIKRouter to auto search, or use `nm -a libswiftCore.dylib` to get the new value.");
                return;
            }
            Dl_info dlinfo;
            dladdr(_conformsToProtocols, &dlinfo);
            if (dlinfo.dli_sname == NULL) {
                NSCAssert1(NO, @"Invalid address(0x%lx) to fetch function pointer of `_conformsToProtocols` in libswiftCore.dylib. Can't find any function. Remove SWIFT_CONFORMSTOPROTOCOLS_ADDRESS and let ZIKRouter to auto search, or use `nm -a libswiftCore.dylib` to get the new value.",address);
                return;
            }
            if (strstr(dlinfo.dli_sname,"_conformsToProtocols") == NULL) {
                NSCAssert2(NO, @"Invalid address(0x%lx) to fetch function pointer of `_conformsToProtocols` in libswiftCore.dylib. The function pointer is not for `_conformsToProtocols`, but for `%s`.  Remove SWIFT_CONFORMSTOPROTOCOLS_ADDRESS and let ZIKRouter to auto search, or use `nm -a libswiftCore.dylib` to get the new value.",address,dlinfo.dli_sname);
                return;
            }
        }
    });
    
    return (bool(*)(void *, void *, void *, void *))_conformsToProtocols;
}

static void *dereferencedPointer(void *pointer) {
    void **deref = pointer;
    return *deref;
}

bool _swift_typeConformsToProtocol(id swiftType, id swiftProtocol) {
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
    BOOL isSwiftType = [swiftType isKindOfClass:SwiftObjectClass] || [swiftType isKindOfClass:_SwiftValueClass];
    BOOL isSwiftProtocol = [swiftProtocol isKindOfClass:SwiftObjectClass] || [swiftProtocol isKindOfClass:_SwiftValueClass];
    if ([swiftType isKindOfClass:NSClassFromString(@"Protocol")]) {
        if (isSwiftProtocol) {
            return NO;
        }
        isSwiftType = YES;
    }
    NSCParameterAssert(isSwiftType || [swiftType isKindOfClass:[NSObject class]]);
    NSCParameterAssert(isSwiftProtocol || [swiftProtocol isKindOfClass:NSClassFromString(@"Protocol")]);
    
    if (!isSwiftType && !isSwiftProtocol) {
        return class_conformsToProtocol(swiftType, swiftProtocol);
    }
    
    bool (*_conformsToProtocols)(void *, void *, void *, void *) = swift_conformsToProtocols();
    if (_conformsToProtocols == NULL) {
        return false;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    void* swiftTypeOpaqueValue;
    void* swiftTypeMetadata;
    if ([swiftType isKindOfClass:SwiftObjectClass]) {
        //swift class
        swiftTypeMetadata = (__bridge void *)(swiftType);
        swiftTypeOpaqueValue = (__bridge void *)(swiftType);
    } else if ([swiftType isKindOfClass:_SwiftValueClass]) {
        //swift struct or swift enum
        NSCAssert2([swiftType respondsToSelector:NSSelectorFromString(_swiftValueString)], @"Swift value(%@) doesn't have method(%@), the API may be changed in libswiftCore.dylib.",swiftType,_swiftValueString);
        swiftTypeOpaqueValue = (__bridge void *)[swiftType performSelector:NSSelectorFromString(_swiftValueString)];
        swiftTypeMetadata = dereferencedPointer(swiftTypeOpaqueValue);
    } else {
        //objc class or objc protocol
        swiftTypeMetadata = (__bridge void *)(swiftType);
        swiftTypeOpaqueValue = (__bridge void *)(swiftType);
    }
    
    void* swiftProtocolOpaqueValue;
    void* swiftProtocolMetadata;
    if ([swiftProtocol isKindOfClass:_SwiftValueClass]) {
        NSCAssert2([swiftProtocol respondsToSelector:NSSelectorFromString(_swiftValueString)], @"Swift value(%@) doesn't have method(%@), the API may be changed in libswiftCore.dylib.",swiftProtocol,_swiftValueString);
        swiftProtocolOpaqueValue = (__bridge void *)[swiftProtocol performSelector:NSSelectorFromString(_swiftValueString)];
        swiftProtocolMetadata = dereferencedPointer(swiftProtocolOpaqueValue);
    } else {
        swiftProtocolMetadata = (__bridge void *)(swiftProtocol);
        swiftProtocolOpaqueValue = (__bridge void *)(swiftProtocol);
    }
#pragma clang diagnostic pop
    bool result = _conformsToProtocols(swiftTypeOpaqueValue, swiftTypeMetadata, swiftProtocolMetadata, NULL);
    return result;
#else
    return true;
#endif
}

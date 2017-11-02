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

void ZIKRouter_enumerateClassList(void(^handler)(Class class)) {
    NSCParameterAssert(handler);
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    // from http://stackoverflow.com/a/8731509/46768
    classes = (Class *)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    for (NSInteger i = 0; i < numClasses; i++) {
        Class class = classes[i];
        if (class) {
            handler(class);
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

bool ZIKRouter_isObjcProtocol(id protocol) {
    if ([[protocol class] isEqual:NSClassFromString(@"Protocol")]) {
        return true;
    }
    return false;
}

static long addressSlideForImage(const char *imagePath) {
    long base = NSNotFound;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t index = 0; index < imageCount; index++) {
        const char *imageName = _dyld_get_image_name(index);
        if (strstr(imageName, imagePath) != NULL) {
            base = _dyld_get_image_vmaddr_slide(index);
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
     long base = addressSlideForImage(libFileName);
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
         strcmp(dlinfo.dli_fname, libFileName) == 0)) {
//        NSCAssert2(NO, @"Invalid address(0x%lx) to fetch function pointer in library file(%s). Address may be too large. Remove SWIFT_CONFORMSTOPROTOCOLS_ADDRESS and let ZIKRouter auto search.",address,libFileName);
        return NULL;
    }
    if (dlinfo.dli_saddr != realAddr) {
//        NSCAssert2(NO, @"Invalid address(0x%lx) to fetch function pointer in library file(%s). Can't find any function at this address. Remove SWIFT_CONFORMSTOPROTOCOLS_ADDRESS and let ZIKRouter auto search.",address,libFileName);
        return NULL;
    }
    
    return realAddr;
}

void* fuzzySearchFunctionPointerBySymbol(const char *libFileName, const char *fuzzyFunctionSymbol) {
    NSCParameterAssert(libFileName);
    NSCParameterAssert(fuzzyFunctionSymbol);
    long base = NSNotFound;
    long nextBase = NSNotFound;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t index = 0; index < imageCount; index++) {
        const char *imageName = _dyld_get_image_name(index);
        if (strstr(imageName, libFileName) != NULL) {
            base = _dyld_get_image_vmaddr_slide(index);
            if (index != imageCount - 1) {
                nextBase = _dyld_get_image_vmaddr_slide(index + 1);
            }
            break;
        }
    }
    if (base == NSNotFound) {
        NSCAssert1(NO, @"Invalid library file(%s), not exist or not be loaded.",libFileName);
        return NULL;
    }
    __block void *foundAddress = 0;
    long startAddress = base;
    long endAddress = base * 2;
    
    if (nextBase != NSNotFound && nextBase > base) {
        endAddress = nextBase;
    }
    Dl_info dlinfo;
    for (long addr = startAddress; addr < endAddress;) {
        dladdr((void *)addr, &dlinfo);
        const char *symbol = dlinfo.dli_sname;
        if (symbol && strlen(symbol) > 0) {
            if (strstr(symbol, fuzzyFunctionSymbol) == NULL) {
                addr += 0x10;
                if (addr < (long)dlinfo.dli_saddr) {
                    addr = (long)dlinfo.dli_saddr + 0x10;
                }
                continue;
            }
            foundAddress = dlinfo.dli_saddr;
            break;
        } else {
            addr += 0x10;
            if (addr < (long)dlinfo.dli_saddr) {
                addr = (long)dlinfo.dli_saddr + 0x10;
            }
        }
    }
    return foundAddress;
}

void* searchFunctionPointerBySymbol(const char *libFileName, const char *functionSymbol) {
    NSCParameterAssert(libFileName);
    NSCParameterAssert(functionSymbol);
    long base = NSNotFound;
    long nextBase = NSNotFound;
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t index = 0; index < imageCount; index++) {
        const char *imageName = _dyld_get_image_name(index);
        if (strstr(imageName, libFileName) != NULL) {
            base = _dyld_get_image_vmaddr_slide(index);
            if (index != imageCount - 1) {
                nextBase = _dyld_get_image_vmaddr_slide(index + 1);
            }
            break;
        }
    }
    if (base == NSNotFound) {
        NSCAssert1(NO, @"Invalid library file(%s), not exist or not be loaded.",libFileName);
        return NULL;
    }
    __block void *foundAddress = 0;
    long startAddress = base;
    long endAddress = base * 2;
    
    if (nextBase != NSNotFound && nextBase > base) {
        endAddress = nextBase;
    }
    Dl_info dlinfo;
    for (long addr = startAddress; addr < endAddress;) {
        dladdr((void *)addr, &dlinfo);
        const char *symbol = dlinfo.dli_sname;
        if (symbol && strlen(symbol) > 0) {
            if (strcmp(symbol, functionSymbol) != 0) {
                addr += 0x10;
                if (addr < (long)dlinfo.dli_saddr) {
                    addr = (long)dlinfo.dli_saddr + 0x10;
                }
                continue;
            }
            foundAddress = dlinfo.dli_saddr;
            break;
        } else {
            addr += 0x10;
            if (addr < (long)dlinfo.dli_saddr) {
                addr = (long)dlinfo.dli_saddr + 0x10;
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
            NSLog(@"\n⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳⏳\nZIKRouter:: _swift_typeConformsToProtocol():\nEnvironment variable SWIFT_CONFORMSTOPROTOCOLS_ADDRESS was not found.\nStart searching function pointer for\n`bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)` in libswiftCore.dylib to validate swift type in debug mode.\nThis is a heavy operation, will cost about 12 second ...\nWhen the search completes, you need to set environment variable SWIFT_CONFORMSTOPROTOCOLS_ADDRESS.\n\n");
            _conformsToProtocols = fuzzySearchFunctionPointerBySymbol(libswiftCorePath.UTF8String, "_conformsToProtocols");
            address = (long)_conformsToProtocols;
            NSLog(@"\n✅ZIKRouter: function pointer 0x%lx is found for `_conformsToProtocols`.\nSet 0x%lx as environment variable SWIFT_CONFORMSTOPROTOCOLS_ADDRESS to avoid search function pointer again for later run.\n\n",address,address - addressSlideForImage(libswiftCorePath.UTF8String));
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
    
    return _conformsToProtocols;
}

bool _swift_typeConformsToProtocol(id swiftType, id swiftProtocol) {
    //Encrypted string
    NSString *_SwiftValueString = [NSString stringWithCString:(char[]){0x5f,0x53,0x77,0x69,0x66,0x74,0x56,0x61,0x6c,0x75,0x65,'\0'} encoding:NSASCIIStringEncoding];
    NSString *SwiftObjectString = [NSString stringWithCString:(char[]){0x53,0x77,0x69,0x66,0x74,0x4f,0x62,0x6a,0x65,0x63,0x74,'\0'} encoding:NSASCIIStringEncoding];
    NSString *_swiftValueString = [NSString stringWithCString:(char[]){0x5f,0x73,0x77,0x69,0x66,0x74,0x56,0x61,0x6c,0x75,0x65,'\0'} encoding:NSASCIIStringEncoding];
    NSString *_swiftTypeMetadataString = [NSString stringWithCString:(char[]){0x5f,0x73,0x77,0x69,0x66,0x74,0x54,0x79,0x70,0x65,0x4d,0x65,0x74,0x61,0x64,0x61,0x74,0x61,'\0'} encoding:NSASCIIStringEncoding];
    
    Class _SwiftValueClass = NSClassFromString(_SwiftValueString);
    Class SwiftObjectClass = NSClassFromString(SwiftObjectString);
    BOOL isSwiftType = [swiftType isKindOfClass:SwiftObjectClass] || [swiftType isKindOfClass:_SwiftValueClass];
    BOOL isSwiftProtocol = [swiftProtocol isKindOfClass:SwiftObjectClass] || [swiftProtocol isKindOfClass:_SwiftValueClass];
    NSCParameterAssert(isSwiftType || [swiftType isKindOfClass:[NSObject class]]);
    NSCParameterAssert(isSwiftProtocol || [swiftProtocol isKindOfClass:NSClassFromString(@"Protocol")]);
    
    if (!isSwiftType && !isSwiftProtocol) {
        return class_conformsToProtocol(swiftType, swiftProtocol);
    }
    
    bool (*_conformsToProtocols)(void *, void *, void *, void *) = swift_conformsToProtocols();
    if (_conformsToProtocols == NULL) {
        return false;
    }
    void* swiftProtocolMetadata;
    void* swiftProtocolValue;
    if ([swiftProtocol isKindOfClass:_SwiftValueClass]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSCAssert([swiftProtocol respondsToSelector:NSSelectorFromString(_swiftTypeMetadataString)], @"Swift value doesn't have method, the API may be changed in libswiftCore.dylib.");
        NSCAssert([swiftProtocol respondsToSelector:NSSelectorFromString(_swiftValueString)], @"Swift value doesn't have method, the API may be changed in libswiftCore.dylib.");
        swiftProtocolMetadata = (__bridge void *)[swiftProtocol performSelector:NSSelectorFromString(_swiftTypeMetadataString)];
        swiftProtocolValue = (__bridge void *)[swiftProtocol performSelector:NSSelectorFromString(_swiftValueString)];
#pragma clang diagnostic pop
    } else {
        swiftProtocolMetadata = (__bridge void *)(swiftProtocol);
        swiftProtocolValue = (__bridge void *)(swiftProtocol);
    }
    
    void* swiftTypeOpaqueValue;
    void* swiftTypeMetadata;
    swiftTypeOpaqueValue = (__bridge void *)(swiftType);
    swiftTypeMetadata = (__bridge void *)(swiftType);
    bool result = _conformsToProtocols(swiftTypeOpaqueValue, swiftTypeMetadata, swiftProtocolMetadata, NULL);
    return result;
}

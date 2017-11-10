//
//  ZIKRouterRuntimeHelper.h
//  ZIKRouter
//
//  Created by zuik on 2017/9/20.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

/**
 Replace a method with another method
 @discussion
 You can call original method by calling the swizzle method name:
 @code
 ZIKRouter_replaceMethodWithMethod([ClassA class],
                                   @selector(myMethod),
                                   [ClassB class],
                                   @selector(hooked_myMethod));
 
 @implementation ClassA
 - (void)myMethod {
     NSLog(@"Call origin method");
 }
 @end
 
 @implementation ClassB
 - (void)hooked_myMethod {
     //Call origin method
     [self hooked_myMethod];
 }
 @end
 @endcode
 
 @param originalClass The class you want to hook
 @param originalSelector The selector to be hooked. When there are same selector for class method and instance method, instance method is priority.
 @param swizzledClass The class providing the new method
 @param swizzledSelector The selector of new method. When there are same selector for class method and instance method, instance method is priority.
 @return True when hook successfully
 */
extern bool ZIKRouter_replaceMethodWithMethod(Class originalClass, SEL originalSelector,
                                              Class swizzledClass, SEL swizzledSelector);

///Same with ZIKRouter_replaceMethodWithMethod, but you can specify class method or instance method.
extern bool ZIKRouter_replaceMethodWithMethodType(Class originalClass, SEL originalSelector, bool originIsClassMethod,
                                                  Class swizzledClass, SEL swizzledSelector, bool swizzledIsClassMethod);

///Same with ZIKRouter_replaceMethodWithMethod. return the original IMP.
extern IMP ZIKRouter_replaceMethodWithMethodAndGetOriginalImp(Class originalClass, SEL originalSelector,
                                                              Class swizzledClass, SEL swizzledSelector);

///Enumerate all classes
extern void ZIKRouter_enumerateClassList(void(^handler)(Class aClass));

///Enumerate all protocols
extern void ZIKRouter_enumerateProtocolList(void(^handler)(Protocol *protocol));

///Check whether a class is a subclass of another class
extern bool ZIKRouter_classIsSubclassOfClass(Class aClass, Class parentClass);

///Check whether a class is from Apple's system framework, or from your project.
extern bool ZIKRouter_classIsCustomClass(Class aClass);

///Check whether an object is an objc protocol.
extern bool ZIKRouter_isObjcProtocol(id protocol);

/**
 Check whether a swift type conforms to a protocol, working like class_conformsToProtocol() in objective-C.
 @warning
 This function is for debugging assertion and it always return true in release mode. It uses private APIs in Swift bridging class, and these code won't be included in release mode. It need to search a private function pointer in libswiftCore.dylib at first call, and it may take some times:
 `bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)`. See `https://github.com/apple/swift/blob/master/stdlib/public/runtime/Casting.cpp`.
 
 This private function may change in later version of swift, so this function may not work then.
 
 @note
 It costs about 0.8 second to get function pointer of `_conformsToProtocols` by fuzzySearchFunctionPointerBySymbol() and store the pointer. It seems like the address is always the same in a same build configuration of swift version and cpu arch. If you think the searching costs too many times, you can set the address as environment variable `SWIFT_CONFORMSTOPROTOCOLS_ADDRESS`, then we don't have to search agian in next running. You can also use `nm -a libswiftCore.dylib` to dump symbols.
 
 If you need to support fat binary, set SWIFT_CONFORMSTOPROTOCOLS_ADDRESS_ARMV7 and SWIFT_CONFORMSTOPROTOCOLS_ADDRESS_ARMV7S. `nm -a libswiftCore.dylib` will dump symbols for armv7 and armv7s, like: `0038f644 t __ZL20_conformsToProtocolsPKN5swift11OpaqueValueEPKNS_14TargetMetadataINS_9InProcessEEEPKNS_29TargetExistentialTypeMetadataIS4_EEPPKNS_12WitnessTableE`. you need to add 0x1 for the symbol's address for armv7 and armv7s, so the final value to set is 0038f645). If the address you set is invalid, there will be an assert failure.
 
 @param swiftType Any type of swift class, objc class, swift struct, swift enum, objc protocol. But can't be swift protocol.
 @param swiftProtocol The protocol to check, can be swift protocol or objc protocol.
 @return True if the type conforms to the protocol.
 */
extern bool _swift_typeConformsToProtocol(id swiftType, id swiftProtocol);

/**
 Search function pointer in loaded library file which it's symbol contains the fuzzyFunctionSymbol. You can get static function's function pointer which not supported by dlsym().
 @warning
 This function is for debugging and not recommanded to use in release mode. It searchs the symbols in the library and it's a heavy operation.
 @note
 Not all static functions can be found, because it's symbol may be striped in the binary file, e.g. those `<redacted>` in system frameworks.
 
 @param libFileName The loaded library file path of the function.
 @param fuzzyFunctionSymbol The symbol to search.
 @return The first found function pointer which it's symbol contains fuzzyFunctionSymbol. Return NULL when not found.
 */
extern void* fuzzySearchFunctionPointerBySymbol(const char *libFileName, const char *fuzzyFunctionSymbol);

///Async version of fuzzySearchFunctionPointerBySymbol(). If the library is large, this may reduce the cost of time.
extern void asyncFuzzySearchFunctionPointerBySymbol(const char *libFileName, const char *fuzzyFunctionSymbol, void(^completion)(void *functionPointer));

/**
 Search function pointer in loaded library file which it's symbol exact matchs the functionSymbol. You can get static function's function pointer which not supported by dlsym().
 @warning
 This function is for debugging and not recommanded to use in release mode. It searchs the symbols in the library and it's a heavy operation.
 @note
 Not all static functions can be found, because it's symbol may be striped in the binary file, e.g. those `<redacted>` in system frameworks.
 
 @param libFileName The loaded library file path of the function.
 @param functionSymbol The symbol to match.
 @return The founded function pointer exact matching the functionSymbol. Return NULL when not found.
 */
extern void* searchFunctionPointerBySymbol(const char *libFileName, const char *functionSymbol);

///Async version of searchFunctionPointerBySymbol(). If the library is large, this may reduce the cost of time.
extern void asyncSearchFunctionPointerBySymbol(const char *libFileName, const char *fuzzyFunctionSymbol, void(^completion)(void *functionPointer));

//
//  ZIKRouterRuntimeDebug.h
//  ZIKRouter
//
//  Created by zuik on 2018/5/12.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if DEBUG

/**
 Check whether a swift type is the target type(is same type or subclass, or conforms to the target protocol), works like `is` operator in swift. Only available in DEBUG mode.
 @warning
 This function is for type safe checking in DEBUG mode. It uses private APIs in Swift bridging class, and these code won't be compiled in release mode. It will search private function pointer in libswiftCore.dylib when first invoked:
 `bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)`. See `https://github.com/apple/swift/blob/master/stdlib/public/runtime/Casting.cpp`.
 
 @since Swift 3.2
 
 @param sourceType Any type of swift class, objc class, swift struct, swift enum, swift function, swift tuple, objc protocol, swift protocol.
 @param targetType The target type to check, can be swift protocol, objc protocol, swift class, objc class, swift struct, swift enum, swift function, swift tuple.
 @return True if the sourceType is the targetType.
 */
extern bool _swift_typeIsTargetType(id sourceType, id targetType);

/**
 Enumerate symbols in images from app's bundle. Only available in DEBUG mode.
 @discussion
 This function let you check symbols in your project, and get demangled swift symbol. Then you can dynamically enumerate and get symbols of swift type like swift protocols, swift functions, swift classes, swift struct and swift enums.
 @warning
 It uses private API in libswiftCore.dylib, and these code won't be compiled in release mode.
 
 @param handler  Handler for each mangled symbol name, return false to stop. `demangledAsSwift` is for demangling a mangled swift symbol, when `simplified` is true, the demangled symbol will strip module name, extension name and `where` clauses in the swift symbol.
 */
extern void _enumerateSymbolName(bool(^handler)(const char *name, NSString *(^demangledAsSwift)(const char *mangledName, bool simplified)));

#endif

NS_ASSUME_NONNULL_END

//
//  ZIKRouterRuntimeInternal.h
//  ZIKRouter
//
//  Created by zuik on 2017/11/17.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

/**
 Check whether a swift type is the target type(is same type or subclass, or conforms to the target protocol), works like `is` operator in swift.
 @warning
 This function is for debugging assertion and it always return false in release mode. It uses private APIs in Swift bridging class, and these code won't be included in release mode. It will search private function pointer in libswiftCore.dylib when first invoked, and it may take some times:
 `bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)`. See `https://github.com/apple/swift/blob/master/stdlib/public/runtime/Casting.cpp`.
 
 This private function may change in later version of swift, so this function may not work then.
 
 @note
 It costs about 0.5 second to get function pointer of `_conformsToProtocols` by fuzzySearchFunctionPointerBySymbol() and store the pointer. It seems like the address is always the same in a same build configuration of swift version and cpu arch. If the searching costs too many times, you can set the address as environment variable `SWIFT_CONFORMSTOPROTOCOLS_ADDRESS`, then we don't have to search agian in next running.
 
 If you need to support fat binary, set SWIFT_CONFORMSTOPROTOCOLS_ADDRESS_ARMV7 and SWIFT_CONFORMSTOPROTOCOLS_ADDRESS_ARMV7S. `nm -a libswiftCore.dylib` will dump symbols for armv7 and armv7s, like: `0038f644 t __ZL20_conformsToProtocolsPKN5swift11OpaqueValueEPKNS_14TargetMetadataINS_9InProcessEEEPKNS_29TargetExistentialTypeMetadataIS4_EEPPKNS_12WitnessTableE`. you need to add 0x1 for the symbol's address for armv7 and armv7s, so the final value to set is 0038f645). If the address you set is invalid, there will be an assert failure.
 
 @param sourceType Any type of swift class, objc class, swift struct, swift enum, objc protocol, swift protocol.
 @param targetType The target type to check, can be swift protocol, objc protocol, swift class, objc class, swift struct, swift enum.
 @return True if the sourceType is the targetType.
 */
extern bool _swift_typeIsTargetType(id sourceType, id targetType);

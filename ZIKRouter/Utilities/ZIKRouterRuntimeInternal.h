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
 This function is for debugging assertion and it always return false in release mode. It uses private APIs in Swift bridging class, and these code won't be included in release mode. It will search private function pointer in libswiftCore.dylib when first invoked:
 `bool _conformsToProtocols(const OpaqueValue *value, const Metadata *type, const ExistentialTypeMetadata *existentialType, const WitnessTable **conformances)`. See `https://github.com/apple/swift/blob/master/stdlib/public/runtime/Casting.cpp`.
 
 This private function may change in later version of swift, so this function may not work then.
 
 @param sourceType Any type of swift class, objc class, swift struct, swift enum, objc protocol, swift protocol.
 @param targetType The target type to check, can be swift protocol, objc protocol, swift class, objc class, swift struct, swift enum.
 @return True if the sourceType is the targetType.
 */
extern bool _swift_typeIsTargetType(id sourceType, id targetType);

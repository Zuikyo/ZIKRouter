//
//  NSString+Demangle.h
//  ZIKRouter
//
//  Created by zuik on 2018/5/15.
//  Copyright © 2018 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#if DEBUG

/** Demangles symbols for various languages. Only available in DEBUG mode.
 */
@interface NSString (Demangle)

/**
 Demangle as a Swift symbol with full type information. Only available when use swift code.
 
 @return The demangled string or self if it can't be demangled as Swift.
 */
- (NSString *)demangledAsSwift;

/**
 Demangle as a simplified Swift symbol. Module name, extension name, `where` clauses will be striped. Only available when use swift code.
 
 @return The demangled string or self if it can't be demangled as Swift.
 */
- (NSString *)demangledAsSimplifiedSwift;

@end

#endif

NS_ASSUME_NONNULL_END

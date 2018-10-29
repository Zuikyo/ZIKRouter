//
//  ZIKFindSymbol.hpp
//  ZIKRouter
//
//  Created by zuik on 2017/12/22.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#ifndef FindSymbol_hpp
#define FindSymbol_hpp

#include <stdio.h>

#if DEBUG

typedef const void *ZIKImageRef;

/// Get beginning address of a loaded image.
extern ZIKImageRef ZIKGetImageByName(const char *file);

/**
 Find function pointer address of a symbol in the loaded image. You can get static function's address which not supported by dlsym().
 @note
 Not all static functions can be found, because its symbol may be striped in the binary file, e.g. those `<redacted>` in system frameworks.
 
 @param image The image to search in, pass NULL to search in all images.
 @param name The symbol to completely match. Need to add `_` when finding a C function name.
 @return Address of the symbol, NULL when symbol was not found.
 */
extern void *ZIKFindSymbol(ZIKImageRef image, const char *name);

/**
 Find function pointer address of a symbol in the loaded image. You can get static function's address which not supported by dlsym().
 @note
 Not all static functions can be found, because its symbol may be striped in the binary file, e.g. those `<redacted>` in system frameworks.

 @param image The image to search in, pass NULL to search in all images.
 @param matchingBlock The block to check the symbol name, return true if the name is matched.
 @return Address of the symbol, NULL when symbol was not found.
 */
extern void *ZIKFindSymbol(ZIKImageRef image, bool(^matchingBlock)(const char *));

/// Get symbol of a address.
extern const char *ZIKSymbolNameForAddress(void *address);

/// Get image file path of a address.
extern const char *ZIKImagePathForAddress(void *address);

#endif
#endif

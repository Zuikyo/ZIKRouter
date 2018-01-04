//
//  FindSymbol.hpp
//  ZIKRouter
//
//  Created by zuik on 2017/12/22.
//  Copyright © 2017年 zuik. All rights reserved.
//

#ifndef FindSymbol_hpp
#define FindSymbol_hpp

#include <stdio.h>

typedef const void *ZIKImageRef;

///Get begin address of a loaded image.
extern ZIKImageRef ZIKGetImageByName(const char *file);

/**
 Find function pointer address of a symbol in the loaded image. You can get static function's address which not supported by dlsym().
 @note
 Not all static functions can be found, because it's symbol may be striped in the binary file, e.g. those `<redacted>` in system frameworks.
 
 @param image The image to search in, pass NULL to search in all images.
 @param name The symbol to find. Need to add `_` when finding a C function name.
 @param matchAsSubstring Pass false to make exact match, true to find the first address matching the `name` as substring.
 */
extern void *ZIKFindSymbol(ZIKImageRef image, const char *name, bool matchAsSubstring);

///Get symbol of a address.
extern const char *ZIKGetSymbolByAddress(void *address);

///Get image file path of a address.
extern const char *ZIKGetImageFileByAddress(void *address);
#endif

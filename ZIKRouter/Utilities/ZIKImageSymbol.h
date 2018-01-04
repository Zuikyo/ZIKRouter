//
//  ZIKImageSymbol.h
//  ZIKRouter
//
//  Created by zuik on 2017/12/22.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZIKImageSymbol : NSObject

typedef const void *ZIKImageRef;

///Get begin address of a loaded image.
+(ZIKImageRef)imageByName:(const char *)file;

/**
 Find function pointer address of a symbol in the loaded image. You can get static function's address which not supported by dlsym().
 @note
 Not all static functions can be found, because it's symbol may be striped in the binary file, e.g. those `<redacted>` in system frameworks.
 
 @param image The image to search in, pass NULL to search in all images.
 @param symbolName The symbol to find. Need to add `_` when finding a C function name.
 @param matchAsSubstring Pass false to make exact match, true to find the first address matching the `name` as substring.
 @return Address of the symbol.
 */
+(void *)findSymbolInImage:(ZIKImageRef)image name:(const char *)symbolName matchAsSubstring:(BOOL)matchAsSubstring;

///Get symbol of a address.
+ (nullable NSString *)symbolByAddress:(void *)address;

///Get image file path of a address.
+ (nullable NSString *)imageFileByAddress:(void *)address;
@end

NS_ASSUME_NONNULL_END

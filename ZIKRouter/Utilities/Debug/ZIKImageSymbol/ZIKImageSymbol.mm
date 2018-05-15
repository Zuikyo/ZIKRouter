//
//  ZIKImageSymbol.m
//  ZIKRouter
//
//  Created by zuik on 2017/12/22.
//  Copyright © 2017 zuik. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#if DEBUG

#import "ZIKImageSymbol.h"
#import "ZIKFindSymbol.h"
#import <mach-o/dyld.h>

@implementation ZIKImageSymbol

+ (ZIKImageRef)imageByName:(const char *)file {
    ZIKImageRef image = ZIKGetImageByName(file);
    return image;
}

+ (void)enumerateImages:(BOOL(^)(ZIKImageRef image, NSString *path))handler {
    if (handler == nil) {
        return;
    }
    uint32_t images = _dyld_image_count();
    for (uint32_t image = 0; image != images; ++image) {
        NSString *path = [NSString stringWithUTF8String:_dyld_get_image_name(image)];
        BOOL result = handler(_dyld_get_image_header(image), path);
        if (result == NO) {
            break;
        }
    }
}

+ (void *)findSymbolInImage:(ZIKImageRef)image name:(const char *)symbolName {
    NSParameterAssert(symbolName);
    void *symbol = ZIKFindSymbol(image, symbolName);
    return symbol;
}

+ (void *)findSymbolInImage:(ZIKImageRef)image matching:(BOOL(^)(const char *symbolName))matchingBlock {
    NSParameterAssert(matchingBlock);
    void *symbol = ZIKFindSymbol(image, ^bool(const char *symbolName) {
        return matchingBlock(symbolName);
    });
    return symbol;
}

+ (nullable NSString *)symbolNameForAddress:(void *)address {
    if (address == NULL) {
        return nil;
    }
    const char *name = ZIKSymbolNameForAddress(address);
    if (name == NULL) {
        return nil;
    }
    if (strlen(name) == 0) {
        return nil;
    }
    return [NSString stringWithUTF8String:name];
}

+ (nullable NSString *)imagePathForAddress:(void *)address {
    if (address == NULL) {
        return nil;
    }
    const char *imageFile = ZIKImagePathForAddress(address);
    if (imageFile == NULL) {
        return nil;
    }
    if (strlen(imageFile) == 0) {
        return nil;
    }
    return [NSString stringWithUTF8String:imageFile];
}

@end

#endif

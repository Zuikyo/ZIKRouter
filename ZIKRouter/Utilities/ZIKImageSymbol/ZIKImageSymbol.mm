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

#import "ZIKImageSymbol.h"
#import "ZIKFindSymbol.h"

@implementation ZIKImageSymbol

+(ZIKImageRef)imageByName:(const char *)file {
    ZIKImageRef image = ZIKGetImageByName(file);
    return image;
}

+(void *)findSymbolInImage:(ZIKImageRef)image name:(const char *)symbolName matchAsSubstring:(BOOL)matchAsSubstring {
    NSParameterAssert(image);
    NSParameterAssert(symbolName);
    void *symbol = ZIKFindSymbol(image, symbolName, matchAsSubstring);
    return symbol;
}

+ (nullable NSString *)symbolNameForAddress:(void *)address {
    const char *name = ZIKSymbolNameForAddress(address);
    if (strlen(name) == 0) {
        return nil;
    }
    return [NSString stringWithUTF8String:name];
}

+ (nullable NSString *)imagePathForAddress:(void *)address {
    const char *imageFile = ZIKImagePathForAddress(address);
    if (strlen(imageFile) == 0) {
        return nil;
    }
    return [NSString stringWithUTF8String:imageFile];
}

@end


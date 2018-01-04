//
//  ZIKImageSymbol.m
//  ZIKRouter
//
//  Created by zuik on 2017/12/22.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import "ZIKImageSymbol.h"
#import "FindSymbol.h"

@implementation ZIKImageSymbol

+(ZIKImageRef)imageByName:(const char *)file {
    ZIKImageRef image = ZIKGetImageByName(file);
    return image;
}

+(void *)findSymbolInImage:(ZIKImageRef)image name:(const char *)symbolName matchAsSubstring:(BOOL)matchAsSubstring {
    void *symbol = ZIKFindSymbol(image, symbolName, matchAsSubstring);
    return symbol;
}

+ (nullable NSString *)symbolByAddress:(void *)address {
    const char *symbol = ZIKGetSymbolByAddress(address);
    if (strlen(symbol) == 0) {
        return nil;
    }
    return [NSString stringWithUTF8String:symbol];
}

+ (nullable NSString *)imageFileByAddress:(void *)address {
    const char *imageFile = ZIKGetImageFileByAddress(address);
    if (strlen(imageFile) == 0) {
        return nil;
    }
    return [NSString stringWithUTF8String:imageFile];
}

@end


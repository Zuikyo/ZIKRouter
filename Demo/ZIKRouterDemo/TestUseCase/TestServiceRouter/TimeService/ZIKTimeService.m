//
//  ZIKTimeService.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTimeService.h"

@implementation ZIKTimeService

+ (instancetype)sharedInstance {
    static ZIKTimeService *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [ZIKTimeService new];
    });
    return shared;
}

- (NSString *)currentTimeString {
    NSDate *date = [NSDate date];
    return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
}

@end

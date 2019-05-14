//
//  ZIKSimpleLabelProtocol.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/6.
//  Copyright © 2017 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZIKRouter/ZIKViewRoutable.h>

@protocol ZIKSimpleLabelProtocol <ZIKViewRoutable>
@property(nullable, nonatomic,copy) NSString *text;
@property(nonatomic) CGRect frame;
@end

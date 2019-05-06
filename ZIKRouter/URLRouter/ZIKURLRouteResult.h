//
//  ZIKURLRouteResult.h
//  ZIKRouter
//
//  Created by zuik on 2019/4/30.
//  Copyright © 2019 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZIKURLRouteResult : NSObject
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDictionary *parameters;
@property (nonatomic, strong) id identifier;
@end

NS_ASSUME_NONNULL_END

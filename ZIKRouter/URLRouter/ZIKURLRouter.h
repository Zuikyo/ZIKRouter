//
//  ZIKURLRouter.h
//  ZIKRouter
//
//  Created by zuik on 2019/4/20.
//  Copyright © 2019 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ZIKURLRouteResult;

/**
 A simple URL router.
 
 Supported patterns:
 
 app://service/path
 app://service/path?k=v&k2&v2
 app://service/path/:id
 app://service/path/:id/:number
 app://service/path/:id/:number?k=v&k2&v2
 app://service/path/:id/path/:number
 */
@interface ZIKURLRouter : NSObject

- (void)registerURLPattern:(NSString *)pattern;
- (ZIKURLRouteResult *)resultForURL:(NSString *)url;

@end

NS_ASSUME_NONNULL_END

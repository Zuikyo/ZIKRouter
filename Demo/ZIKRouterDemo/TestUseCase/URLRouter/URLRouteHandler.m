//
//  URLRouteHandler.m
//  ZIKRouterDemo
//
//  Created by zuik on 2018/5/14.
//  Copyright © 2018 zuik. All rights reserved.
//

#import "URLRouteHandler.h"
@import ZIKRouter.Internal;

// This declaration makes all UIViewController get AOP callback
DeclareRoutableView(UIViewController, URLRouteHandler)
@implementation URLRouteHandler

+ (void)registerRoutableDestination {
    [self registerView:[UIViewController class]];
}

- (id<ZIKRoutableView>)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIViewController *destination = [[UIViewController alloc] init];
    return destination;
}

// Do common handle in AOP
+ (void)router:(ZIKViewRouter *)router willPerformRouteOnDestination:(UIViewController *)destination fromSource:(id)source {
    if (router == nil) {
        return;
    }
    NSDictionary *userInfo = router.original_configuration.userInfo;
    if ([userInfo objectForKey:@"url"]) {
        // From URL Scheme
        NSString *title = destination.title;
        if (title == nil) {
            title = @"";
        }
        title = [title stringByAppendingString:@"-fromURL"];
        destination.title = title;
    }
}
@end

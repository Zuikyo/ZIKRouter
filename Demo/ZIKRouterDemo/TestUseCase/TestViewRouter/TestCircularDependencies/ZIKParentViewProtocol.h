//
//  ZIKParentViewProtocol.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/10/14.
//  Copyright © 2017 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>
@import ZIKRouter;

@protocol ZIKChildViewProtocol;
@protocol ZIKParentViewProtocol <ZIKViewRoutable>
@property (nonatomic, strong) id<ZIKChildViewProtocol> child;
@end

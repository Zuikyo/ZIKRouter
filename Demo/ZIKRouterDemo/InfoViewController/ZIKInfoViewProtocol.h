//
//  ZIKInfoViewProtocol.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZIKRouter/ZIKViewRoutable.h>

@class UIViewController;
@protocol ZIKInfoViewDelegate <NSObject>

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController;

@end

#define _ZIKInfoViewProtocol_ (Protocol<ZIKViewRoutable> *)@protocol(ZIKInfoViewProtocol)
@protocol ZIKInfoViewProtocol <ZIKViewRoutable>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, weak) id<ZIKInfoViewDelegate> delegate;
@end

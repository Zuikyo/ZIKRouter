//
//  ZIKInfoViewProtocol.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ZIKInfoViewDelegate <NSObject>

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController;

@end

#define _ZIKInfoViewProtocol_ (Protocol<ZIKRoutableViewDynamicGetter> *)@protocol(ZIKInfoViewProtocol)
@protocol ZIKInfoViewProtocol <NSObject>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, weak) id<ZIKInfoViewDelegate> delegate;
@end

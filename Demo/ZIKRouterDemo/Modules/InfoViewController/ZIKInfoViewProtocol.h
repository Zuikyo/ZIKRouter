//
//  ZIKInfoViewProtocol.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/5.
//  Copyright © 2017 zuik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZIKRouter/ZIKViewRoutable.h>
#import <ZIKRouter/ZIKViewModuleRoutable.h>

NS_ASSUME_NONNULL_BEGIN

@class UIViewController;
@protocol ZIKInfoViewDelegate <NSObject>

- (void)handleRemoveInfoViewController:(UIViewController *)infoViewController;

@end

@protocol ZIKInfoViewProtocol <ZIKViewRoutable>
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, weak) id<ZIKInfoViewDelegate> delegate;
@end

@protocol EasyInfoViewProtocol1 <ZIKInfoViewProtocol, ZIKViewRoutable>
@end
@protocol EasyInfoViewProtocol2 <ZIKInfoViewProtocol, ZIKViewRoutable>
@end
@protocol EasyInfoViewModuleProtocol <ZIKViewModuleRoutable>
@property (nonatomic, copy, readonly) id<ZIKInfoViewProtocol> _Nullable(^makeDestinationWith)(NSString *name, NSInteger age, __weak _Nullable id<ZIKInfoViewDelegate> delegate);
@property (nonatomic, copy, readonly) void(^constructDestination)(NSString *name, NSInteger age, __weak _Nullable id<ZIKInfoViewDelegate> delegate);
@property (nonatomic, copy, nullable) void(^didMakeDestination)(id<ZIKInfoViewProtocol> destination);
@end

NS_ASSUME_NONNULL_END

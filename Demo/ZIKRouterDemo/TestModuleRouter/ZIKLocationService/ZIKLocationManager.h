//
//  ZIKLocationManager.h
//
//  Created by zuik on 2016/11/7.
//  Copyright © 2016年 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const ZIKLocationManagerErrorDomain;
typedef NS_ENUM(NSInteger, ZIKLocationManagerErrorCode) {
    ZIKLocationManagerErrorTimeout = -2000,
    ZIKLocationManagerErrorLocationServiceDisabled,
    ZIKLocationManagerErrorNotAuthorized,
    ZIKLocationManagerErrorLocateFailed
};
@class CLLocationManager;
@class CLLocation;

typedef void(^ZIKLocationManagerLocationUpdateBlock)(CLLocationManager *manager, NSArray *locations);
typedef void(^ZIKLocationManagerLocationUpdateFailBlock)(CLLocationManager *_Nullable manager, NSError *error);

///定位工具
@interface ZIKLocationManager : NSObject

///使用系统定位，回调在主线程
- (void)startUpdatingLocationWithBlock:(ZIKLocationManagerLocationUpdateBlock)updateBlock
                            errorBlock:(ZIKLocationManagerLocationUpdateFailBlock)errorBlcok;

- (void)stopUpdatingLocation;
@end

NS_ASSUME_NONNULL_END

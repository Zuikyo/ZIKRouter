//
//  ZIKLocationManager.m
//
//  Created by 张玮珂 on 2016/11/7.
//  Copyright © 2016年 张玮珂. All rights reserved.
//

#import "ZIKLocationManager.h"
#import <CoreLocation/CoreLocation.h>
//#import "JZLocationConverter.h"

NSString *const ZIKLocationManagerErrorDomain = @"ZIKLocationManagerErrorDomain";

@interface ZIKLocationManager ()<CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, copy) ZIKLocationManagerLocationUpdateBlock systemUpdateBlock;
@property (nonatomic, copy) ZIKLocationManagerLocationUpdateFailBlock systemFailBlock;
@property (nonatomic, assign) CLAuthorizationStatus currentStatus;
@property (nonatomic, strong) id retainSelf;
@end

@implementation ZIKLocationManager

- (void)startUpdatingLocationWithBlock:(ZIKLocationManagerLocationUpdateBlock)updateBlock errorBlock:(ZIKLocationManagerLocationUpdateFailBlock)errorBlcok {
    self.retainSelf = self;
    self.systemUpdateBlock = updateBlock;
    self.systemFailBlock = errorBlcok;
    
    if (![CLLocationManager locationServicesEnabled]) {
        [self dy_systemLocationErrorCallback:nil error:[self dy_errorWithCode:ZIKLocationManagerErrorLocationServiceDisabled]];
        return;
    }
    
    [self dy_checkAuthStateAndStartLocate];
}

- (void)dy_checkAuthStateAndStartLocate {
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    self.currentStatus = authStatus;
    if (authStatus == kCLAuthorizationStatusRestricted || authStatus == kCLAuthorizationStatusDenied) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = [self dy_errorWithCode:ZIKLocationManagerErrorNotAuthorized];
            [self dy_systemLocationErrorCallback:nil error:error];
        });
        return;
    }
    
    if (!_locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    if (authStatus == kCLAuthorizationStatusNotDetermined) {
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
            [_locationManager requestWhenInUseAuthorization];
            return;
        }
    }
    [_locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    self.systemUpdateBlock = nil;
    self.systemFailBlock = nil;
    [_locationManager stopUpdatingLocation];
    self.retainSelf = nil;
}

#pragma mark block回调

- (void)dy_systemLocationSuccessCallback:(CLLocationManager *)manager locations:(NSArray *)locations {
    if (_systemUpdateBlock) {
        _systemUpdateBlock(manager, locations);
    }
}

- (void)dy_systemLocationErrorCallback:(CLLocationManager *)manager error:(NSError *)error {
    if (_systemFailBlock) {
        _systemFailBlock(manager, error);
        self.retainSelf = nil;
    }
}

- (NSError *)dy_errorWithCode:(ZIKLocationManagerErrorCode)errorCode {
    NSString *description;
    switch (errorCode) {
        case ZIKLocationManagerErrorTimeout:
            description = @"定位超时";
            break;
        case ZIKLocationManagerErrorLocationServiceDisabled:
            description = @"定位服务未开启";
            break;
        case ZIKLocationManagerErrorNotAuthorized:
            description = @"定位权限被用户拒绝";
            break;
        case ZIKLocationManagerErrorLocateFailed:
            description = @"定位失败";
            break;
    }
    return [NSError errorWithDomain:ZIKLocationManagerErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey:description}];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (_currentStatus == status) {
        return;
    }
    if ([CLLocationManager locationServicesEnabled] && _currentStatus == kCLAuthorizationStatusNotDetermined) {
        [self dy_checkAuthStateAndStartLocate];
    }
    self.currentStatus = status;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSError *locateError;
    if (error.code == kCLErrorDenied) {
        locateError = [self dy_errorWithCode:ZIKLocationManagerErrorNotAuthorized];
    } else {
        locateError = [NSError errorWithDomain:ZIKLocationManagerErrorDomain code:error.code userInfo:error.userInfo];
    }
    [self dy_systemLocationErrorCallback:manager error:locateError];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSMutableArray<CLLocation *> *fixedLocations = [NSMutableArray array];
    for (CLLocation *location in locations) {
//        CLLocationCoordinate2D fixedCoordinate = [JZLocationConverter wgs84ToGcj02:location.coordinate];
        CLLocation *fixedLocation = [[CLLocation alloc] initWithCoordinate:location.coordinate altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:location.course speed:location.speed timestamp:location.timestamp];
        [fixedLocations addObject:fixedLocation];
    }
    
    [self dy_systemLocationSuccessCallback:manager locations:[fixedLocations copy]];
}

@end

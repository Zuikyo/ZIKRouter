//
//  ZIKViewRoutePath+CompatibleAlert.h
//  ZIKCompatibleAlert
//
//  Created by zuik on 2018/4/24.
//  Copyright © 2018 zuik. All rights reserved.
//

#import <ZIKRouter/ZIKViewRouter.h>

@interface ZIKViewRoutePath (CompatibleAlert)

@property (nonatomic, class, readonly) ZIKViewRoutePath *(^presentCompatibleAlertFrom)(UIViewController *source);

@end

//
//  ObjcViewController.h
//  ZRouterTests
//
//  Created by zuik on 2018/5/23.
//  Copyright © 2018 zuik. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ObjcViewInput
@end

@protocol ObjcViewSubInput <ObjcViewInput>
@end

@interface ObjcViewController : UIViewController<ObjcViewSubInput>

@end

@interface ObjcSubViewController : ObjcViewController

@end

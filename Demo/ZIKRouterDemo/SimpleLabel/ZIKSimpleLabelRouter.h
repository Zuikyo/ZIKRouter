//
//  ZIKSimpleLabelRouter.h
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/6.
//  Copyright © 2017年 zuik. All rights reserved.
//

#import <ZIKRouterKit/ZIKRouterKit.h>
#import "ZIKSimpleLabelProtocol.h"

DeclareRoutableViewProtocol(ZIKSimpleLabelProtocol, ZIKSimpleLabelRouter)
@interface ZIKSimpleLabelRouter : ZIKViewRouter <ZIKViewRouterProtocol>

@end

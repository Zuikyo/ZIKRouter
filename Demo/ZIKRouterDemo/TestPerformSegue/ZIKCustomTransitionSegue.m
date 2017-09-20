//
//  ZIKCustomTransitionSegue.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/11.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKCustomTransitionSegue.h"

@implementation ZIKCustomTransitionSegue

///If a custom segue provide custom present, you should use ZIKViewRouteTypeCustom to provide custom remove.
- (void)perform {
    UIViewController *source = self.sourceViewController;
    UIViewController *destination = self.destinationViewController;
    
    //Transition without transitionCoordinator
    [source addChildViewController:destination];
    destination.view.frame = source.view.frame;
    [source.view addSubview:destination.view];
    destination.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
    
    //ZIKViewRouter use UIViewController's transitionCoordinator to do completion, so this will let the router complete before animation real complete
    [UIView animateWithDuration:2 animations:^{
        destination.view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [destination didMoveToParentViewController:source];
    }];
    
    //Unbalanced transition 1
//    destination.view.frame = source.view.frame;
//    [source.view addSubview:destination.view];
//    destination.view.transform = CGAffineTransformMakeScale(0.1, 0.1);
//    [UIView animateWithDuration:2 animations:^{
//        destination.view.transform = CGAffineTransformIdentity;
//    } completion:^(BOOL finished) {
//        [destination.view removeFromSuperview];
//        //removeFromSuperview will call viewWillDisAppear: and viewDidDisappear: asyncly, so -presentViewController:animated:completion: here will lead to unbalanced transition
//        [source presentViewController:destination animated:NO completion:^{
//            
//        }];
//    }];
    
    
    //Unbalanced transition 2
    //transition same view controller
//    [source addChildViewController:destination];
//    [source transitionFromViewController:destination
//                        toViewController:destination
//                                duration:2
//                                 options:UIViewAnimationOptionCurveEaseInOut
//                              animations:^{
//        
//    } completion:^(BOOL finished) {
//        
//    }];
}

@end

//
//  TestAutoCreateViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/7.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestAutoCreateViewController.h"

@interface TestAutoCreateViewController ()

@end

@implementation TestAutoCreateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1) {
        [self pushManually];
    } else if (indexPath.row == 3) {
        [self presentManually];
    }
}

- (UIViewController *)emptyContainerViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"emptyContainer"];
}

///Route UIViewController by code manually won't auto create a corresponding router, but router classes registered with the view controller will get AOP callback. The reason is we can't find which view controller is the performer invoking -pushViewController:animated:. The performer may be a child view controller of any view controller in the navigation stack.
- (void)pushManually {
    UIViewController *emptyContainerViewController = [self emptyContainerViewController];
    [self.navigationController pushViewController:emptyContainerViewController animated:YES];
}

///Route UIViewController by code manually won't auto create a corresponding router, but router classes registered with the view controller will get AOP callback
- (void)presentManually {
    UIViewController *emptyContainerViewController = [self emptyContainerViewController];
    [self presentViewController:emptyContainerViewController animated:YES completion:^{
        
    }];
}

#pragma mark - Navigation

//If segue is performed by code, this method is not called
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(nullable id)sender {
    return YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {
    //If return NO, route in -perfromUnwindSegueToTestPerformSegueVCFromInfoVC will fail and callback with error code ZIKViewRouteErrorSegueNotPerformed
    return YES;
}

- (IBAction)unwindToTestAutoCreateViewController:(UIStoryboardSegue *)sender {
    NSLog(@"%@: did unwind to TestAutoCreateViewController",self);
}

@end

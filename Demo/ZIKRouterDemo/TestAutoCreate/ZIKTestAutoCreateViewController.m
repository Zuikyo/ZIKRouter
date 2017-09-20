//
//  ZIKTestAutoCreateViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/7/7.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestAutoCreateViewController.h"

@interface ZIKTestAutoCreateViewController ()

@end

@implementation ZIKTestAutoCreateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
//    return 0;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
//    return 0;
//}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1) {
        [self pushManually];
    } else if (indexPath.row == 3) {
        [self presentManually];
    }
}

- (UIViewController *)demoParentViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"emptyDemoParent"];
}

///Route UIViewController by code manually won't auto create a corresponding router, but router classes registered with the view controller will get AOP callback. The reason is we can't find which view controller is the performer invoking -pushViewController:animated:. The performer may be a child view controller of any view controller in the navigation stack.
- (void)pushManually {
    UIViewController *demoParentViewController = [self demoParentViewController];
    [self.navigationController pushViewController:demoParentViewController animated:YES];
}

///Route UIViewController by code manually won't auto create a corresponding router, but router classes registered with the view controller will get AOP callback
- (void)presentManually {
    UIViewController *demoParentViewController = [self demoParentViewController];
    [self presentViewController:demoParentViewController animated:YES completion:^{
        
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

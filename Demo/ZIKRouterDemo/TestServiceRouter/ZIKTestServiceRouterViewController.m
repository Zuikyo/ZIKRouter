//
//  ZIKTestServiceRouterViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "ZIKTestServiceRouterViewController.h"
#import "ZIKTimeServiceInput.h"
@import ZIKRouter;
#import "ZIKTimeServiceRouter.h"

@interface ZIKTestServiceRouterViewController ()
@property (nonatomic, strong) id<ZIKTimeServiceInput> timeService;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation ZIKTestServiceRouterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
- (IBAction)callTimeService:(id)sender {
    NSString *timeString = [self.timeService currentTimeString];
    self.timeLabel.text = timeString;
}

- (id<ZIKTimeServiceInput>)timeService {
    if (!_timeService) {
        NSAssert([ZIKServiceRouter.toService(ZIKTimeServiceInput_routable) completeSynchronously] == YES, @"We need to get service synchronously");
        id<ZIKTimeServiceInput> timeService = [ZIKServiceRouter.toService(ZIKTimeServiceInput_routable) makeDestination];
        _timeService = timeService;
    }
    return _timeService;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

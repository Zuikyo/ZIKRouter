//
//  TestServiceRouterViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2017/8/9.
//  Copyright © 2017 zuik. All rights reserved.
//

#import "TestServiceRouterViewController.h"
#import "ZIKTimeServiceInput.h"
@import ZIKRouter;
#import "ZIKTimeServiceRouter.h"

@interface TestServiceRouterViewController ()
@property (nonatomic, strong) id<ZIKTimeServiceInput> timeService;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end

@implementation TestServiceRouterViewController

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
        id<ZIKTimeServiceInput> timeService = [ZIKRouterToService(ZIKTimeServiceInput) makeDestination];
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

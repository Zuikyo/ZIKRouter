//
//  TestURLRouterViewController.m
//  ZIKRouterDemo
//
//  Created by zuik on 2018/5/3.
//  Copyright © 2018年 zuik. All rights reserved.
//

#import "TestURLRouterViewController.h"

@interface TestURLRouterViewController () <UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, strong) NSArray<NSString *> *routerIdentifiers;
@property (nonatomic, copy) NSString *selectedIdentifier;
@end

@implementation TestURLRouterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectedIdentifier = @"com.zuik.viewController.testPush";
    self.routerIdentifiers = @[
                               @"com.zuik.viewController.testPush",
                               @"com.zuik.viewController.testPresentModally",
                               @"com.zuik.viewController.testPresentAsPopover",
                               @"com.zuik.viewController.testPerformSegue",
                               @"com.zuik.viewController.testShow",
                               @"com.zuik.viewController.testShowDetail",
                               @"com.zuik.viewController.testAddAsChild",
                               @"com.zuik.viewController.testAddAsSubview",
                               @"com.zuik.viewController.testCustom",
                               @"com.zuik.viewController.testGetDestination",
                               @"com.zuik.viewController.testAutoCreate",
                               @"com.zuik.viewController.testCircularDependencies",
                               @"com.zuik.viewController.testClassHierarchy",
                               @"com.zuik.viewController.testServiceRouter",
                               @"com.zuik.viewController.swiftSample",
                               @"com.zuik.viewController.testURLRouter"
                               ];
    
    self.view.backgroundColor = [UIColor whiteColor];
    UIPickerView *pickerView = [[UIPickerView alloc] init];
    pickerView.delegate = self;
    pickerView.dataSource = self;
    [self.view addSubview:pickerView];
    pickerView.translatesAutoresizingMaskIntoConstraints = NO;
    [pickerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    [pickerView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:50].active = YES;
    [pickerView.widthAnchor constraintEqualToConstant:300].active = YES;
    [pickerView.heightAnchor constraintEqualToConstant:500].active = YES;
    
    UIButton *jumpButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [jumpButton setTitle:@"jump" forState:UIControlStateNormal];
    [jumpButton addTarget:self action:@selector(openURL:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:jumpButton];
    jumpButton.translatesAutoresizingMaskIntoConstraints = NO;
    [jumpButton.centerXAnchor constraintEqualToAnchor:pickerView.centerXAnchor].active = YES;
    [jumpButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-50].active = YES;
    [jumpButton.widthAnchor constraintEqualToConstant:50].active = YES;
    [jumpButton.heightAnchor constraintEqualToConstant:30].active = YES;
}

- (void)openURL:(id)sender {
    NSString *url = [NSString stringWithFormat:@"router://%@",self.selectedIdentifier];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.routerIdentifiers.count;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *title = [self.routerIdentifiers objectAtIndex:row];
    title = [title stringByReplacingOccurrencesOfString:@"com.zuik.viewController." withString:@""];
    return title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedIdentifier = [self.routerIdentifiers objectAtIndex:row];
}

@end

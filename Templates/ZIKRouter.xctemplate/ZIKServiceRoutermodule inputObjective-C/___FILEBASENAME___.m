//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#import "___VARIABLE_productName___.h"
#import <ZIKRouter/ZIKRouterInternal.h>
#import <ZIKRouter/ZIKServiceRouterInternal.h>
#import "___VARIABLE_destinationClass___.h"

DeclareRoutableService(___VARIABLE_destinationClass___, ___VARIABLE_productName___)
DeclareRoutableServiceModuleProtocol(___VARIABLE_moduleProtocolName___)

@interface ___VARIABLE_productName___ ()

@end

@implementation ___VARIABLE_productName___

+ (void)registerRoutableDestination {
    [self registerExclusiveService:[___VARIABLE_destinationClass___ class]];
    [self registerModuleProtocol:ZIKRoutable(___VARIABLE_moduleProtocolName___)];
}

// Return your custom configuration
+ (ZIKServiceMakeableConfiguration<___VARIABLE_moduleProtocolName___> *)defaultRouteConfiguration {
    ZIKServiceMakeableConfiguration<___VARIABLE_destinationClass___ *> *config = [[ZIKServiceMakeableConfiguration<___VARIABLE_destinationClass___ *> alloc] init];
    __weak typeof(config) weakConfig = config;
    config.constructDestination = ^(/*arguments*/) {
        weakConfig.makeDestination = ^{
#error TODO: instantiate destination
            // Instantiate destination. Return nil if configuration is invalid.
            ___VARIABLE_destinationClass___ *destination = [[___VARIABLE_destinationClass___ alloc] init];
            return destination;
        };
    };
    return config;
}

- (nullable ___VARIABLE_destinationClass___ *)destinationWithConfiguration:(ZIKServiceMakeableConfiguration<___VARIABLE_moduleProtocolName___> *)configuration {
    if (configuration.makeDestination) {
        return configuration.makeDestination();
    }
#error TODO: instantiate destination
    // Instantiate destination with configuration. Return nil if configuration is invalid.
    ___VARIABLE_destinationClass___ *destination = [[___VARIABLE_destinationClass___ alloc] init];

    return destination;
}

- (void)prepareDestination:(___VARIABLE_destinationClass___ *)destination configuration:(ZIKServiceMakeableConfiguration<___VARIABLE_moduleProtocolName___> *)configuration {
    // Prepare destination
}

@end

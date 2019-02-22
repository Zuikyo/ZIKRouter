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
    ZIKServiceMakeableConfiguration<id<___VARIABLE_protocolName___>> *config = [[ZIKServiceMakeableConfiguration alloc] init];
    __weak typeof(config) weakConfig = config;
    
    config._prepareDestination = ^(id<___VARIABLE_protocolName___> destination) {
        // Prepare destination
    };
    
    config.makeDestinationWith = ^id<___VARIABLE_protocolName___> _Nullable(/*arguments*/) {
        weakConfig.makeDestination = ^id<___VARIABLE_protocolName___> _Nullable{
#error TODO: instantiate destination
            // Instantiate destination. Return nil if configuration is invalid.
            ___VARIABLE_destinationClass___ *destination = [[___VARIABLE_destinationClass___ alloc] init];
            return destination;
        };
        weakConfig.makedDestination = weakConfig.makeDestination();
        if (weakConfig._prepareDestination) {
            weakConfig._prepareDestination(weakConfig.makedDestination);
        }
        return weakConfig.makedDestination;
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

@end

//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#import "___VARIABLE_productName___.h"
#import <ZIKRouter/ZIKRouterInternal.h>
#import <ZIKRouter/ZIKViewRouterInternal.h>
#import "___VARIABLE_destinationClass___.h"

DeclareRoutableView(___VARIABLE_destinationClass___, ___VARIABLE_productName___)
DeclareRoutableViewModuleProtocol(___VARIABLE_moduleProtocolName___)

@interface ___VARIABLE_productName___ ()

@end

@implementation ___VARIABLE_productName___

+ (void)registerRoutableDestination {
    [self registerExclusiveView:[___VARIABLE_destinationClass___ class]];
    [self registerModuleProtocol:ZIKRoutable(___VARIABLE_moduleProtocolName___)];
}

// Return your custom configuration
+ (ZIKViewMakeableConfiguration<___VARIABLE_moduleProtocolName___> *)defaultRouteConfiguration {
    ZIKViewMakeableConfiguration<id<___VARIABLE_protocolName___>> *config = [[ZIKViewMakeableConfiguration alloc] init];
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

- (nullable ___VARIABLE_destinationClass___ *)destinationWithConfiguration:(ZIKViewMakeableConfiguration<___VARIABLE_moduleProtocolName___> *)configuration {
    if (configuration.makeDestination) {
        return configuration.makeDestination();
    }
#error TODO: instantiate destination
    // Instantiate destination with configuration. Return nil if configuration is invalid.
    ___VARIABLE_destinationClass___ *destination = [[___VARIABLE_destinationClass___ alloc] init];
    
    return destination;
}

/*
 // If the destiantion is UIView / NSView, override and return route types for UIView / NSView
 + (ZIKViewRouteTypeMask)supportedRouteTypes {
 return ZIKViewRouteTypeMaskViewDefault;
 }
 */

@end

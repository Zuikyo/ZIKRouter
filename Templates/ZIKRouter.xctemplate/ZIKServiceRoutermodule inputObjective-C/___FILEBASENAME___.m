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
#import "___VARIABLE_protocolName___.h"


@interface ___VARIABLE_configClass___()
@end
@implementation ___VARIABLE_configClass___
 
 - (id)copyWithZone:(nullable NSZone *)zone {
     ___VARIABLE_configClass___ *copy = [super copyWithZone:zone];
     //Set values to copy
     return copy;
 }
 
@end

DeclareRoutableService(___VARIABLE_destinationClass___, ___VARIABLE_productName___)

@interface ___VARIABLE_productName___ ()

@end

@implementation ___VARIABLE_productName___

+ (void)registerRoutableDestination {
    [self registerExclusiveService:[___VARIABLE_destinationClass___ class]];
    [self registerModuleProtocol:ZIKRoutable(___VARIABLE_protocolName___)];
}

- (nullable ___VARIABLE_destinationClass___ *)destinationWithConfiguration:(ZIKPerformRouteConfiguration *)configuration {
#error TODO: instantiate destination
    // Instantiate destination with configuration. Return nil if configuration is invalid.
    ___VARIABLE_destinationClass___ *destination = [[___VARIABLE_destinationClass___ alloc] init];
    
    return destination;
}

- (void)prepareDestination:(___VARIABLE_destinationClass___ *)destination configuration:(ZIKPerformRouteConfiguration *)configuration {
    // Prepare destination
}

 // Return your custom configuration
+ (___VARIABLE_configClass___ *)defaultRouteConfiguration {
    return [[___VARIABLE_configClass___ alloc] init];
}

@end

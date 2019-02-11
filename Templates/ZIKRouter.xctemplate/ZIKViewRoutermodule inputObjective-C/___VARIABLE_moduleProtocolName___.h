//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#import <ZIKRouter/ZIKViewModuleRoutable.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ___VARIABLE_protocolName___;

#error TODO: replace /*arguments*/ with type of module config parameters
@protocol ___VARIABLE_moduleProtocolName___ <ZIKViewModuleRoutable>
@property (nonatomic, copy, readonly) void(^constructDestination)(/*arguments*/);
@property (nonatomic, copy, nullable) void(^didMakeDestination)(id<___VARIABLE_protocolName___> destination);
@end

NS_ASSUME_NONNULL_END

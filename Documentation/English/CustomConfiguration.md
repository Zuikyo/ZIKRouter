# Transfer Parameters with Custom Configuration

Router can use custom configuration to transfer custom parameters.

## When to use custom configuration

When the destination class uses custom initializers to create instance, router needs to get required parameter from the caller. 

When your module contains multi components, and you need to pass parameters to those components. And those parameters do not belong to the destination. 

For example, when you pass a model to a VIPER module, the destination is the view in VIPER, and the view is not responsible for accepting any models.

You need a module config protocol to store them in configuration, and configure components' dependencies inside the router.

## Module Config Protocol

Module protocol is for declaring parameters used by the module, conformed by the configuration of the router.

Instead of  `EditorViewInput`, we use another routable protocol `EditorViewModuleInput`  as config protocol for routing:

```swift
protocol EditorViewModuleInput: class {
    // Transfer parameters and make destination
    var makeDestinationWith: (viewModel: EditorViewModel, _ note: Note) -> EditorViewInput? { get }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@protocol EditorViewModuleInput <ZIKViewModuleRoutable>
 //  Transfer parameters for making destination
 @property (nonatomic, copy, readonly) id<EditorViewInput> _Nullable(^makeDestinationWith)(EditorViewModel *viewModel, Note *note);
 @end
```

</details>

In general, a module config protocol only contains `makeDestinationWith`, for declaring parameters and destination type. You can also add other properties or methods.

## Configuration Subclass

You can use a configuration subclass and store parameters on its properties.

```swift
// Configuration subclass conforming to EditorViewModuleInput
class EditorViewModuleConfiguration<T>: ZIKViewMakeableConfiguration<NoteEditorViewController>, EditorViewModuleInput {
    // User is responsible for calling makeDestinationWith and giving parameters
    var makeDestinationWith: (viewModel: EditorViewModel, _ note: Note) -> EditorViewInput? {
        return { viewModel, note in
                
            // Prepare the destination
            self.__prepareDestination = { destination in
                let presenter = EditorPresenter()
                let interactor = EditorInteractor()
                destination.presenter = presenter
                presenter.view = destination
                presenter.interactor = interactor
                // Pass note to the data manager
                interactor.note = note
            }
            
            // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
            // MakeDestination will be used for creating destination instance
            self.makeDestination = { [unowned self] () in
                // Use custom initializer, pass view model to view
                let destination = NoteEditorViewController(viewModel: viewModel)
                return destination
            }
            
            if let destination = self.makeDestination?() {
                self.__prepareDestination?(destination)
                // The router won't make and prepare destination again when perform with this configuration
                self.makedDestination = destination
                return destination
            }
            return nil
        }
    }
}

func makeEditorViewModuleConfiguration() -> ZIKViewMakeableConfiguration<NoteEditorViewController> & EditorViewModuleInput {
    return EditorViewModuleConfiguration<Any>()
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
// Configuration subclass conforming to EditorViewModuleInput
@interface EditorViewModuleConfiguration: ZIKViewMakeableConfiguration<NoteEditorViewController *><EditorViewModuleInput>
@end

@implementation EditorViewModuleConfiguration

// User is responsible for calling makeDestinationWith and giving parameters
- (id<EditorViewInput> _Nullable(^)(Note *))makeDestinationWith {
    return ^id<EditorViewInput> _Nullable(EditorViewModel *viewModel, Note *note) {
        
        // Prepare the destination
        self._prepareDestination = ^(NoteEditorViewController *destination) {
            EditorPresenter *presenter = [EditorPresenter alloc] init];
            EditorInteractor *interactor = [EditorInteractor alloc] init];
            destination.presenter = presenter;
            presenter.view = destination;
            presenter.interactor = interactor;
            // Pass note to the data manager
            interactor.note = note;
        };
        
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
        self.makeDestination = ^ NoteEditorViewController * _Nullable{
            // Use custom initializer, pass view model to view
            NoteEditorViewController *destination = [NoteEditorViewController alloc] initWithViewModel:viewModel];
            return destination;
        };
        
        // Set makedDestination so router will use this destination when performing
        self.makedDestination = self.makeDestination();
        if (self._prepareDestination) {
            self._prepareDestination(self.makedDestination);
        }
        return self.makedDestination;
    };
}

@end

ZIKViewMakeableConfiguration<NoteEditorViewController *> * makeEditorViewModuleConfiguration() {
    return [EditorViewModuleConfiguration new];
}
```

</details>

Swift generic class is not OC class. It won't be in the `__objc_classlist` section of the Mach-O file. So it won't affect the app launching time.

Transferring parameters with `makeDestinationWith` block can reduce much glue code. We don't need to store parameters in some properties, just pass them through block.

## Without Configuration Subclass

If the protocol is very simple and you don't need a configuration subclass, or you're using Objective-C and don't want too many subclass, you can choose generic class`ViewMakeableConfiguration`and`ZIKViewMakeableConfiguration`:

```swift
extension ViewMakeableConfiguration: EditorViewModuleInput where Destination == EditorViewInput, Constructor == (EditorViewModel, Note) -> EditorViewInput? {
}

// ViewMakeableConfiguration with generic arguments works as the same as  EditorViewModuleConfiguration
// The config works like EditorViewModuleConfiguration<Any>()
func makeEditorViewModuleConfiguration() -> ViewMakeableConfiguration<EditorViewInput, (EditorViewModel, Note) -> EditorViewInput?> {
    let config = ViewMakeableConfiguration<EditorViewInput, (EditorViewModel, Note) -> EditorViewInput?>({ _,_ in})        
    
    // User is responsible for calling makeDestinationWith and giving parameters
    config.makeDestinationWith = { [unowned config] (viewModel, note) in
                                  
        // Prepare the destination
        config._prepareDestination = { destination in
            let presenter = EditorPresenter()
            let interactor = EditorInteractor()
            destination.presenter = presenter
            presenter.view = destination
            presenter.interactor = interactor
            // Pass note to the data manager
            interactor.note = note
        };
        
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
        config.makeDestination = { () in
            // Use custom initializer, pass view model to view
            let destination = NoteEditorViewController(viewModel: viewModel)            
            return destination
        }
        if let destination = config.makeDestination?() {
            config.__prepareDestination?(destination)
            // The router won't make and prepare destination again when perform with this configuration
            config.makedDestination = destination
            return destination
        }
        return nil
    }
    return config
}

```

<details><summary>Objective-C Sample</summary>

Generic class`ZIKViewMakeableConfiguration`has property`makeDestinationWith`with`id(^)()`type. `id(^)()`means the block can accept any parameters. So you can declare your custom parameters of `makeDestinationWith` in protocol.

```objectivec
// The config works like EditorViewModuleConfiguration
ZIKViewMakeableConfiguration<NoteEditorViewController *> * makeEditorViewModuleConfiguration(void) {
    ZIKViewMakeableConfiguration<NoteEditorViewController *> *config = [ZIKViewMakeableConfiguration<id<EditorViewInput>> new];
    __weak typeof(config) weakConfig = config;        
    
    // User is responsible for calling makeDestinationWith and giving parameters
    config.makeDestinationWith = ^id<EditorViewInput> _Nullable(EditorViewModel *viewModel, Note *note) {
        
        // Prepare the destination
        config._prepareDestination = ^(id<EditorViewInput> destination) {
        	EditorPresenter *presenter = [EditorPresenter alloc] init];
            EditorInteractor *interactor = [EditorInteractor alloc] init];
            destination.presenter = presenter;
            presenter.view = destination;
            presenter.interactor = interactor;
            // Pass note to the data manager
            interactor.note = note;
    	};
        
        // Capture parameters in makeDestination, so we don't need configuration subclass to hold the parameters
        // MakeDestination will be used for creating destination instance
        weakConfig.makeDestination = ^ NoteEditorViewController * _Nullable{
            // Use custom initializer, pass view model to view
            NoteEditorViewController *destination = [NoteEditorViewController alloc] initWithViewModel:viewModel];            
            return destination;
        };
        // Set makedDestination so router will use this destination when performing
        weakConfig.makedDestination = weakConfig.makeDestination();
        if (weakConfig._prepareDestination) {
            weakConfig._prepareDestination(weakConfig.makedDestination);
        }
        return weakConfig.makedDestination;
    };
    return config;
}
```

</details>

## Use Configuration in Router

Override`defaultRouteConfiguration`in router to use your custom configuration:

```swift
class EditorViewRouter: ZIKViewRouter<NoteEditorViewController, ZIKViewMakeableConfiguration<NoteEditorViewController>> {
    
    override class func registerRoutableDestination() {
        // Register class
        registerView(NoteEditorViewController.self)
        // Register module config protocol, then we can use this protocol to fetch the router
        register(RoutableViewModule<EditorViewModuleInput>())
    }
    
    // Use custom configuration
    override class func defaultRouteConfiguration() -> ZIKViewMakeableConfiguration<NoteEditorViewController> {
        return makeEditorViewModuleConfiguration()
    }
    
    override func destination(with configuration: ZIKViewMakeableConfiguration<NoteEditorViewController>) -> NoteEditorViewController? {
        if let makeDestination = configuration.makeDestination {
            return makeDestination()
        }
        return nil
    }
    
}
```

<details><summary>Objective-C Sample</summary>

```swift
@interface EditorViewRouter: ZIKViewRouter<NoteEditorViewController, ZIKViewMakeableConfiguration<NoteEditorViewController *>>
@end
@implementation EditorViewRouter {

+ (void) registerRoutableDestination {
    // Register class
    [self registerView:[NoteEditorViewController class]];
    // Register module config protocol, then we can use this protocol to fetch the router
    [self registerModuleProtocol:ZIKRoutable(EditorViewModuleInput)];
}
    
// Use custom configuration
+(ZIKViewMakeableConfiguration<NoteEditorViewController *> *)defaultRouteConfiguration() {
    return makeEditorViewModuleConfiguration();
}

- (NoteEditorViewController *)destinationWithConfiguration:(ZIKViewMakeableConfiguration<NoteEditorViewController *> *)configuration {
    if (configuration.makeDestination) {
        return configuration.makeDestination();
    }
    return nil;
}

}
```

</details>

If you're not using router subclass, you can register config factory to create route:

```swift
// Register EditorViewModuleInput and factory function of custom configuration
ZIKAnyViewRouter.register(RoutableViewModule<EditorViewModuleInput>(),
   forMakingView: NoteEditorViewController.self, 
   making: makeEditorViewModuleConfiguration)

```

<details><summary>Objective-C Sample</summary>

```objectivec
// Register EditorViewModuleInput and factory function of custom configuration
[ZIKModuleViewRouter(EditorViewModuleInput)
     registerModuleProtocol:ZIKRoutable(EditorViewModuleInput)
     forMakingView:[NoteEditorViewController class]
     factory: makeEditorViewModuleConfiguration];

```

</details>

`ViewMakeableConfiguration` `ZIKViewMakeableConfiguration` `ServiceMakeableConfiguration` `ZIKServiceMakeableConfiguration`all conform to`ZIKConfigurationMakeable`. The `didMakeConfiguration` in these configuration will be automatically invoked.

## How to use

The user can use the module with its module config protocol and transfer parameters:

```swift
var viewModel = ...
var note = ...
Router.makeDestination(to: RoutableViewModule<EditorViewModuleInput>()) { (config) in
     // Transfer parameters and get EditorViewInput
     let destination = config.makeDestinationWith(note)
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
EditorViewModel *viewModel = ...
Note *note = ...
[ZIKRouterToViewModule(EditorViewModuleInput)
    performPath:ZIKViewRoutePath.showFrom(self)
    configuring:^(ZIKViewRouteConfiguration<EditorViewModuleInput> *config) {
        // Transfer parameters and get EditorViewInput
        id<EditorViewInput> destination = config.makeDestinationWith(note);
 }];
```

</details>

In this design pattern, we reduce much glue code for transferring parameters, and the module can re-declare their parameters with generic arguments and module config protocol.

You can use the generic configuration to reduce subclass count. And You can also transfer complicated parameters with a configuration subclass, such as multi `makeDestinationWith` for multi situations.

```swift
protocol EditorViewModuleInput: class {    
    var makeDestinationWith: (_ viewModel: EditorViewModel, _ note: Note) -> EditorViewInput? { get }
    var makeDestinationForNewNoteWith: (_ noteName: String) -> EditorViewInput? { get }
}

extension ViewMakeableConfiguration: EditorViewModuleInput where Destination == EditorViewInput, Constructor == (EditorViewModel, Note) -> EditorViewInput? {
    var makeDestinationForNewNoteWith: (String) -> EditorViewInput? {
        get {
            if let block = self.constructorContainer["makeDestinationForNewNoteWith"] as? (String) -> EditorViewInput? {
                return block
            }
            return { _ in return nil }
        }
        set {
            self.constructorContainer["makeDestinationForNewNoteWith"] = newValue
        }
    }
}
```
<details><summary>Objective-C Sample</summary>

```objectivec
@protocol EditorViewModuleInput <ZIKViewModuleRoutable>
@property (nonatomic, copy, readonly) id<EditorViewInput> _Nullable(^makeDestinationWith)(EditorViewModel *viewModel, Note *note);
@property (nonatomic, copy, readonly) id<EditorViewInput> _Nullable(^makeDestinationForNewNoteWith)(EditorViewModel *viewModel, Note *note);
@end

@interface ZIKViewMakeableConfiguration (EditorViewModuleInput) <EditorViewModuleInput>
@end
@implementation ZIKViewMakeableConfiguration (EditorViewModuleInput) 

- (ZIKMakeBlock)makeDestinationForNewNoteWith {
    return self.constructorContainer[@"makeDestinationForNewNoteWith"];
}
- (void)setMakeDestinationForNewNoteWith:(ZIKMakeBlock)block {
    self.constructorContainer[@"makeDestinationForNewNoteWith"] = block;
}
@end
```

</details>

------

#### Next section: [Error Handle](ErrorHandle.md)
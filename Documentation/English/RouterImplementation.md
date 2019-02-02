# Router Implementation

To make your class become modular, you need to create router for your module. You don't need to modify the module's code. That will reduce the cost for refactoring existing modules.

Here is an example for creating router for `EditorViewController`.

Swift sample:

```swift
protocol NoteEditorInput {
    weak var delegate: EditorDelegate? { get set }
    func constructForCreatingNewNote()
}

class EditorViewController: UIViewController, NoteEditorInput {
    ...
}
```
## Router Subclass

Create a `ZIKViewRouter` subclass for `EditorViewController` and override router's interface:

```swift
//EditorViewRouter.swift

//Declare that EditorViewController is routable
extension EditorViewController: ZIKRoutableView {

}
//Declare that NoteEditorInput is routable protocol
extension RoutableView where Protocol == NoteEditorInput {
    init() { self.init(declaredProtocol: Protocol.self) }
}

class EditorViewRouter: ZIKViewRouter<EditorViewController, ZIKViewRouteConfiguration> {
    //Register the router's view and protocol
    override class func registerRoutableDestination() {
        //Register EditorViewController with this router. A router can register multi views, and a view can be registered with multi router
        registerView(EditorViewController.self)
        
        //Register NoteEditorInput, then you can use this protocol to get this router
        register(RoutableView<NoteEditorInput>())
    }
    //Make sure all routable dependencies in this module is available.
    override class func _didFinishRegistration() {
        assert(Router.to(RoutableService<SomeServiceInput>()) != nil)
    }
    
    //Return the destination module
    override func destination(with configuration: ZIKViewRouteConfiguration) -> EditorViewController? {
        // In configuration, you can get parameters from the caller for creating the instance
        let data = // Get data from configuration
        let destination = EditorViewController(data: data)
        return destination
    }
    
    //Whether the destination from storyboard requires dependencies from external
    override func destinationFromExternalPrepared(destination: EditorViewController) -> Bool {
        if (destination.delegate != nil) {
            return true
        }
        return false
    }
    
    //Prepare the destination before performing route, and inject dependencies
    override func prepareDestination(_ destination: EditorViewController, configuration: ZIKViewRouteConfiguration) {
        //Inject dependencies for EditorViewController
    }
    
    //Check dependencies after preparing
    override func didFinishPrepareDestination(_ destination: EditorViewController, configuration: ZIKViewRouteConfiguration) {
        
    }
    
    //AOP for view Router
    override class func router(_ router: ZIKAnyViewRouter?, willPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: ZIKAnyViewRouter?, didPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: ZIKAnyViewRouter?, willRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: ZIKAnyViewRouter?, didRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
//NoteEditorInput.h

//Declare that NoteEditorInput is routable protocol
@protocol NoteEditorInput: ZIKViewRoutable
@property (nonatomic, weak) id<EditorDelegate> delegate;
- (void)constructForCreatingNewNote;
@end
```
```objectivec
@interface EditorViewController: UIViewController <NoteEditorInput>
@end
```

Create a `ZIKViewRouter` subclass for `EditorViewController`:

```objectivec
//EditorViewRouter.h
@interface EditorViewRouter : ZIKViewRouter
@end
```
```objectivec
//EditorViewRouter.m

//Declare that EditorViewController is routable
@interface EditorViewController (EditorViewRouter) <ZIKRoutableView>
@end
@implementation EditorViewController (EditorViewRouter)
@end

@implementation EditorViewRouter

//Register the router's view and protocol
+ (void)registerRoutableDestination {
    //Register EditorViewController with this router. A router can register multi views, and a view can be registered with multi router
    [self registerView:[EditorViewController class]];
    
    //Register NoteEditorInput, then you can use this protocol to get this router
    [self registerViewProtocol:ZIKRoutable(NoteEditorInput)];
}

//Return the destination module
- (nullable EditorViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    // In configuration, you can get parameters from the caller for creating the instance
    id data = // Get data from configuration    
    EditorViewController *destination = [[EditorViewController alloc] initWithData:data];
    return destination;
}

//Whether the destination from storyboard requires dependencies from external
- (BOOL)destinationFromExternalPrepared:(EditorViewController *)destination {
    if (destination.delegate != nil) {
        return YES;
    }
    return NO;
}

//Prepare the destination before performing route, and inject dependencies
- (void)prepareDestination:(EditorViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    //Inject dependencies for EditorViewController
}

//Check dependencies after preparing
- (void)didFinishPrepareDestination:(EditorViewController *)destination configuration:(ZIKViewRouteConfiguration *)configuration {
    
}

//AOP for view router
+ (void)router:(nullable ZIKViewRouter *)router willPerformRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router didPerformRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router willRemoveRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}
+ (void)router:(nullable ZIKViewRouter *)router didRemoveRouteOnDestination:(EditorViewController *)destination fromSource:(id)source {
    
}

@end
```
</details>

The router subclass can set generic parameters when inheriting from ZIKViewRouter. See [Type Checking](TypeChecking.md).

## Simple Router

If your module is very simple and don't need a router subclass, you can just register the class in a simpler way:

```swift
ZIKAnyViewRouter.register(RoutableView<NoteEditorInput>(), forMakingView: EditorViewController.self)
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter registerViewProtocol:ZIKRoutable(NoteEditorInput) forMakingView:[EditorViewController class]];
```

</details>

The destination will be created by`[[RegisteredClass alloc] init]`.

**Note: You should not use this method if the class is pure swift class, or it has custom designated initializer.  It will crash because the class couldn't create instance with `[[RegisteredClass alloc] init]`.**

Or you can register class with custom creating block:

```swift
ZIKAnyViewRouter.register(RoutableView<NoteEditorInput>(), 
                 forMakingView: EditorViewController.self) { (config, router) -> NoteEditorInput? in
                     EditorViewController *destination = ... // instantiate your view controller
                     return destination;
        }

```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRouter
    registerViewProtocol:ZIKRoutable(NoteEditorInput)
    forMakingView:[EditorViewController class]
    making:^id _Nullable(ZIKViewRouteConfiguration *config, ZIKViewRouter *router) {
        EditorViewController *destination = ... // instantiate your view controller
        return destination;
 }];
```

</details>

or with custom factory function:

```swift
function makeEditorViewController(config: ViewRouteConfig) -> NoteEditorInput? {
    NoteEditorViewController *destination = ... // instantiate your view controller
    return destination;
}

ZIKAnyViewRouter.register(RoutableView<NoteEditorInput>(), 
                 forMakingView: NoteEditorViewController.self, making: makeEditorViewController)
```

<details><summary>Objective-C Sample</summary>

```objectivec
id<NoteEditorInput> makeEditorViewController(ZIKViewRouteConfiguration *config) {
    NoteEditorViewController *destination = ... // instantiate your view controller
    return destination;
}

[ZIKViewRouter
    registerViewProtocol:ZIKRoutable(NoteEditorInput)
    forMakingView:[NoteEditorViewController class]
    factory:makeEditorViewController];
```

</details>

or with much more complex blocks:

```swift
ZIKViewRoute<EditorViewController, ViewRouteConfig>
    .make(withDestination: EditorViewController.self,
          makeDestination: { (config, router) -> EditorViewController? in
            return EditorViewController()
    })
    .register(RoutableView<NoteEditorInput>())
```

<details><summary>Objective-C Sample</summary>

```objectivec
[ZIKViewRoute<EditorViewController *, ZIKViewRouteConfig *> 
	makeRouteWithDestination:[EditorViewController class] 
	makeDestination:^ EditorViewController * _Nullable(ZIKViewRouteConfig * _Nonnull config, __kindof ZIKRouter<EditorViewController *,ZIKViewRouteConfig *,ZIKViewRemoveConfiguration *> * _Nonnull router) {
        return [[EditorViewController alloc] init];
    }];
```
</details>

---
#### Next section: [Module Registration](ModuleRegistration.md)
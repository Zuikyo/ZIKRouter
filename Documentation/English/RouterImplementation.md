# Router Implementation

ZIKRouter is an abstract factory design. You need to create router subclass (factory subclass) for your module (product), then implement router's interface. You don't need to modify the module's code.

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
Create a `ZIKViewRouter` subclass for `EditorViewController`:

```swift
//EditorViewRouter.swift

//Declare that EditorViewController is routable
extension EditorViewController: ZIKRoutableView {

}
//Declare that NoteEditorInput is routable protocol
extension RoutableView where Protocol == NoteEditorInput {
    init() { }
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
    override class func _registrationDidFinished() {
        assert(Router.to(RoutableService<SomeServiceInput>()) != nil)
    }
    
    //Return the destination module
    override func destination(with configuration: ZIKViewRouteConfiguration) -> EditorViewController? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "EditorViewController") as! EditorViewController
        return destination
    }
    
    //Whether the destination from storyboard requires dependencies from external
    override static func destinationPrepared(_ destination: EditorViewController) -> Bool {
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
    override class func router(_ router: DefaultViewRouter?, willPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: DefaultViewRouter?, didPerformRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: DefaultViewRouter?, willRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
    }
    override class func router(_ router: DefaultViewRouter?, didRemoveRouteOnDestination destination: EditorViewController, fromSource source: Any?) {
        
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
    [self registerViewProtocol:ZIKRoutableProtocol(NoteEditorInput)];
}

//Return the destination module
- (nullable EditorViewController *)destinationWithConfiguration:(ZIKViewRouteConfiguration *)configuration {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    EditorViewController *destination = [sb instantiateViewControllerWithIdentifier:@"EditorViewController"];
    return destination;
}

//Whether the destination from storyboard requires dependencies from external
+ (BOOL)destinationPrepared:(EditorViewController *)destination {
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

If you don't want to create a complex router subclass for a simple module, you can use block to register the module:

```swift
Registry.register(destination: EditorViewController.self, routableProtocol: NoteEditorInput.self)
	.makeDestination({ config in
		return EditorViewController()
	})
	.prepareDestination({ destination in
		
	})
```

But this feature is not released now.
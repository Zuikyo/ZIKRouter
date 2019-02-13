# 自定义 configuration 传参

Router 可以使用自定义 configuration 传递更多自定义参数。

## 什么时候需要自定义 configuration

有时模块有自定义初始化方法，需要从外部传入一些参数后才能创建实例。

有时需要传递的参数并不能都通过 destination 的接口设置，例如参数不属于 destination，而是属于模块内其他组件。

例如需要向一个模块传递 model 对象，此时 destination 作为 view，在设计上不能接触到 model。此时可以让 router 使用自定义 configuration 保存参数，配合 module config protocol 传参，再在 router 内部用 configuration 去配置模块内的各个部分。

## Module Config Protocol

Module config protocol 用来声明模块需要用到的参数。由自定义 configuration 遵守。

之前用于路由的`NoteEditorInput`是由 destination 遵守的，现在使用`EditorViewModuleInput`进行路由，由自定义的 configuration 遵守，用于声明模块需要的参数：

```swift
protocol EditorViewModuleInput: class {
    // 传递参数，用于创建模块；这里声明了需要两个参数
    var constructDestination: (viewModel: EditorViewModel, _ note: Note) -> Void { get }
    // 声明 destination 的类型为 NoteEditorInput
    var didMakeDestination: ((NoteEditorInput) -> Void)? { get set }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
@protocol EditorViewModuleInput <ZIKViewModuleRoutable>
 // 传递参数，用于创建模块；这里声明了需要两个参数
 @property (nonatomic, copy, readonly) void(^constructDestination)(EditorViewModel *viewModel, Note *note);
 // 声明 destination 的类型为 NoteEditorInput
 @property (nonatomic, copy, nullable) void(^didMakeDestination)(id<NoteEditorInput> destination);
 @end
```

</details>

Module config protocol 里一般只需要`constructDestination`和`didMakeDestination`，分别用于声明参数类型和 destination 类型。也可以添加其他自定义的属性参数或者方法。

## configuration 子类

使用自定义 configuration 时，可以使用 configuration 子类，在子类上用自定义属性传递参数。

```swift
// 使用自定义子类，遵守 EditorViewModuleInput
class EditorViewModuleConfiguration<T>: ZIKViewMakeableConfiguration<NoteEditorViewController>, EditorViewModuleInput {
    var didMakeDestination: ((NoteEditorInput) -> Void)?
    
    // 使用者调用 constructDestination 向模块传参
    var constructDestination: (viewModel: EditorViewModel, _ note: Note) -> Void {
        return { viewModel, note in
        	 // makeDestination 会被用于创建 destination
        	 // 用闭包捕获了传入的参数，可以直接用于创建 destination
            self.makeDestination = { [unowned self] () in
                // 调用自定义初始化方法，把 view mdoel 传给 view
	            let destination = NoteEditorViewController(viewModel: viewModel)
                let presenter = EditorPresenter()
                let interactor = EditorInteractor()
                destination.presenter = presenter
                presenter.view = destination
                presenter.interactor = interactor
                // 把 note 传给数据管理者
                interactor.note = note
                // 把结果传递给外部
                self.didMakeDestination?(destination)
                self.didMakeDestination = nil
                return destination
            }
        }
    }
}

func makeEditorViewModuleConfiguration() -> ZIKViewMakeableConfiguration<NoteEditorViewController> & EditorViewModuleInput {
	return EditorViewModuleConfiguration<Any>()
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
// 使用自定义子类，遵守 EditorViewModuleInput
@interface EditorViewModuleConfiguration: ZIKViewMakeableConfiguration<NoteEditorViewController *><EditorViewModuleInput>
@end

@implementation EditorViewModuleConfiguration

// 使用者调用 constructDestination 向模块传参
- (void(^)(Note *))constructDestination {
    return ^(EditorViewModel *viewModel, Note *note) {
        // makeDestination 会被用于创建 destination
        // 用闭包捕获了传入的参数，可以直接用于创建 destination
        self.makeDestination = ^ NoteEditorViewController * _Nullable{
            // 调用自定义初始化方法，把 view mdoel 传给 view
	        NoteEditorViewController *destination = [NoteEditorViewController alloc] initWithViewModel:viewModel];
            EditorPresenter *presenter = [EditorPresenter alloc] init];
            EditorInteractor *interactor = [EditorInteractor alloc] init];
            destination.presenter = presenter;
            presenter.view = destination;
            presenter.interactor = interactor;
            // 把 note 传给数据管理者
            interactor.note = note;
            return destination;
        };
    };
}

@end

ZIKViewMakeableConfiguration<NoteEditorViewController *> * makeEditorViewModuleConfiguration() {
	return [EditorViewModuleConfiguration new];
}
```

</details>

Swift 泛型类不是 OC Class，不会出现在 Mach-O 的 __objc_classlist 节中，所以不会对 app 的启动速度造成影响。所以只需要给`EditorViewModuleConfiguration`加个泛型`T`后就无需再担心类数量的问题。

通过`constructDestination`block 传递参数可以省去很多胶水代码，通过闭包直接传参，无需通过属性保存参数。所有模块的传参都能统一到一个`constructDestination`方法上。

## 非 configuration 子类

如果你的协议很简单，不需要用到 configuration 子类，或者你用的是 Objective-C，不想创建过多的子类影响 app 启动速度，可以用泛型类`ViewMakeableConfiguration`和`ZIKViewMakeableConfiguration`：

```swift
extension ViewMakeableConfiguration: EditorViewModuleInput where Destination == NoteEditorInput, Constructor == (EditorViewModel, Note) -> Void {
}

// 用泛型类可以实现 EditorViewModuleConfiguration 子类一样的效果
// 此时的 config 相当于 EditorViewModuleConfiguration<Any>()
func makeEditorViewModuleConfiguration() -> ViewMakeableConfiguration<NoteEditorInput, (EditorViewModel, Note) -> Void> {
	let config = ViewMakeableConfiguration<NoteEditorInput, (EditorViewModel, Note) -> Void>({ _,_ in})
	
	// 使用者调用 constructDestination 向模块传参
	config.constructDestination = { [unowned config] (viewModel, note) in
	    // makeDestination 会被用于创建 destination
       // 用闭包捕获了传入的参数，可以直接用于创建 destination
	    config.makeDestination = { () in
	        // 调用自定义初始化方法，把 view mdoel 传给 view
	        let destination = NoteEditorViewController(viewModel: viewModel)
            let presenter = EditorPresenter()
            let interactor = EditorInteractor()
            destination.presenter = presenter
            presenter.view = destination
            presenter.interactor = interactor
            // 把 note 传给数据管理者
            interactor.note = note
	        return destination
	    }
	}
	return config
}

```

<details><summary>Objective-C Sample</summary>

泛型类`ZIKViewMakeableConfiguration`有类型为`void(^)()`的`constructDestination`属性，`void(^)()`表示这个 block 接受可变参数，因此可以通过 protocol 自由声明`constructDestination`的参数。

```objectivec
// 此时的 config 效果和使用子类是一样的
ZIKViewMakeableConfiguration<NoteEditorViewController *> * makeEditorViewModuleConfiguration(void) {
	ZIKViewMakeableConfiguration<NoteEditorViewController *> *config = [ZIKViewMakeableConfiguration<NoteEditorViewController *> new];
	__weak typeof(config) weakConfig = config;
	
	// 配置 constructDestination，使用者调用 constructDestination 向模块传参
	config.constructDestination = ^(EditorViewModel *viewModel, Note *note) {
	    // makeDestination 会被用于创建 destination
	    // 用闭包捕获了传入的参数，可以直接用于创建 destination，不必保存到 configuration 的属性上
	    weakConfig.makeDestination = ^ NoteEditorViewController * _Nullable{
	        // 调用自定义初始化方法，把 view mdoel 传给 view
	        NoteEditorViewController *destination = [NoteEditorViewController alloc] initWithViewModel:viewModel];
            EditorPresenter *presenter = [EditorPresenter alloc] init];
            EditorInteractor *interactor = [EditorInteractor alloc] init];
            destination.presenter = presenter;
            presenter.view = destination;
            presenter.interactor = interactor;
            // 把 note 传给数据管理者
            interactor.note = note;
	        return destination;
	    };
	};
	return config;
}
```

</details>

## Router 中使用 configuration

在创建路由时，在 router 子类中重写`defaultRouteConfiguration`使用自定义的 configuration:

```swift
class EditorViewRouter: ZIKViewRouter<NoteEditorViewController, ZIKViewMakeableConfiguration<NoteEditorViewController>> {
    
    override class func registerRoutableDestination() {
        // 注册 class
        registerView(NoteEditorViewController.self)
        // 注册 module config protocol；之后就可以用这个 protocol 获取 此 router
        register(RoutableViewModule<EditorViewModuleInput>())
    }
    
    // 使用自定义 configuration
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
    // 注册 class
    [self registerView:[NoteEditorViewController class]];
    // 注册 module config protocol；之后就可以用这个 protocol 获取 此 router
    [self registerModuleProtocol:ZIKRoutable(EditorViewModuleInput)];
}
// 使用自定义 configuration
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

也可以用注册 config 创建函数的方式创建路由，不需要使用 router 子类：

```swift
// 注册 EditorViewModuleInput 和自定义 configuration 的创建函数
ZIKAnyViewRouter.register(RoutableViewModule<EditorViewModuleInput>(),
   forMakingView: NoteEditorViewController.self, 
   making: makeEditorViewModuleConfiguration)
```

<details><summary>Objective-C Sample</summary>

```objectivec
// 注册 EditorViewModuleInput 和自定义 configuration 的创建函数
[ZIKModuleViewRouter(EditorViewModuleInput)
     registerModuleProtocol:ZIKRoutable(EditorViewModuleInput)
     forMakingView:[NoteEditorViewController class]
     factory: makeEditorViewModuleConfiguration];
```

</details>

`ViewMakeableConfiguration` `ZIKViewMakeableConfiguration` `ServiceMakeableConfiguration` `ZIKServiceMakeableConfiguration`都遵守`ZIKConfigurationMakeable`，它们的`didMakeConfiguration`会在对象创建后自动调用。

## 调用

使用者在使用模块时就能动态传入参数：

```swift
var viewModel = ...
var note = ...
Router.makeDestination(to: RoutableViewModule<EditorViewModuleInput>()) { (config) in
     // 传递参数
     config.constructDestination(viewModel, note)
     config.didMakeDestination = { destiantion in
        // 得到 NoteEditorInput
     }
}
```

<details><summary>Objective-C Sample</summary>

```objectivec
EditorViewModel *viewModel = ...
Note *note = ...
[ZIKRouterToViewModule(EditorViewModuleInput)
    performPath:ZIKViewRoutePath.showFrom(self)
    configuring:^(ZIKViewRouteConfiguration<EditorViewModuleInput> *config) {
        // 传递参数
        config.constructDestination(viewModel, note);
        config.didMakeDestination = ^(id<NoteEditorInput> destination) {
            // 得到 NoteEditorInput
        };
 }];
```
</details>

这种方式省去了很多胶水代码，通过闭包直接传参，无需通过属性保存参数，而且每个模块都能用泛型和 protocol 重新声明参数类型。

在大多数情况下使用泛型 configuration 来避免创建过多的类，同时在某些复杂场景 configuration 子类则可以提供更复杂的操作，例如有多个初始化方法时，定义多个`constructDestination`方法。

---
#### 下一节：[错误检查](ErrorHandle.md)
# 模块注册

在router里，你必须重写`registerRoutableDestination`方法，注册当前router所管理的类和用于动态路由的protocol。App启动时会自动执行所有router的`registerRoutableDestination`方法。

## 注册destination类

你可以为同一个类创建多个router，例如`UIAlertController`，不同的模块可以对`UIAlertController`进行不同的功能封装，例如A模块创建了一个alert router，用于同时兼容`UIAlertView`和`UIAlertController`，B模块也创建了一个alert router，只是用于封装alert控件。如果要区分使用两个router，就需要分别注册不同的protocol，并在使用时用各自的protocol获取路由。

```swift
class CommonAlertViewRouter: ZIKAnyViewRouter {
    override class func registerRoutableDestination() {
        registerView(UIAlertViewController.self)
        registerView(UIAlertView.self)
        Registry.register(RoutableView<CommonAlertViewInput>(), forRouter: self)
    }
}
```
```swift
class EasyAlertViewRouter: ZIKAnyViewRouter {
    override class func registerRoutableDestination() {
        registerView(UIAlertViewController.self)
        Registry.register(RoutableView<EasyAlertViewInput>(), forRouter: self)
    }
}
```

注册destination的目的一是为了进行错误检查，二是需要支持storyboard，在注册表中寻找view controller对应的router进行配置。

## 独占性

当你为自己的模块创建router，并且在router里进行依赖注入，这时就要求使用者必须使用你创建的router，不能再创建其他router。因此需要用`+registerExclusiveView:`来将模块和router进行单一注册。这时，其他router就不能再注册此模块了，否则在启动时会产生断言错误。

```swift
class EditorViewRouter: ZIKAnyViewRouter {
    override class func registerRoutableDestination() {
        registerExclusiveView(EditorViewController.self)
    }
}
```
当router里管理的destination是公有的时候，使用普通注册，例如UIKit里的公有类、第三方模块中未提供router的类。当destination是你自己拥有的，则使用独占式注册，限制路由的使用。

## protocol注册

你可以在注册destination的同时，注册destination的protocol。之后就能用protocol来获取router类，无需引入router子类。如果没有注册protocol，那么在使用时就只能明确地使用router的具体子类。

同时，在执行路由时，也可以用protocol对destination进行方法注入，实现动态传参。

## destination protocol

如果你的类很简单，所有的依赖注入都可以在destination上直接进行，那么只需要使用destination protocol，只对destination类进行依赖注入。

## module protocol

如果destination是属于一个复杂模块，有多个组件类，而这些组件类的配置无法全部在一个destination类上进行，则应该使用module config protocol，让router在内部初始化各个组件。例如一个需要向一个VIPER模块传递model对象，此时destination类是VIPER中的View，而View在设计上不能接触到model。

```swift
///模块配置协议
protocol EditorModuleConfig {
    var noteModel: Note?
}
///用自定义的ZIKRouteConfiguration子类保存模块配置
class EditorModuleConfiguration: ZIKViewRouteConfiguration, EditorModuleConfig {
    var noteModel: Note?
}

class EditorViewRouter: ZIKViewRouter<EditorViewController, EditorModuleConfiguration> {
    //注册当前Router所管理的view和protocol
    override class func registerRoutableDestination() {
        registerView(EditorViewController.self)
        Registry.register(RoutableViewModule<EditorModuleConfig>(), forRouter: self)
    }
    //使用自定义模块配置
    override defaultConfiguration() -> EditorModuleConfiguration {
        return EditorModuleConfiguration()
    }
    
    //返回需要获取的目的模块
    override func destination(with configuration: EditorModuleConfiguration) -> EditorViewController? {
        let sb = UIStoryboard.init(name: "Main", bundle: nil)
        let destination = sb.instantiateViewController(withIdentifier: "EditorViewController") as! EditorViewController
        return destination
    }
    
    //在执行路由前配置模块，执行依赖注入
    override func prepareDestination(_ destination: EditorViewController, configuration: EditorModuleConfiguration) {
        //配置VIPER模块
        let view = destination
        guard view.presenter == nil else {
            return
        }
        let presenter = EditorPresenter()
        let interactor = EditorInteractor()
        
        //把model传递给interactor
        interactor.note = configuration.noteModel
        
        presenter.interactor = interactor
        presenter.view = view
        view.presenter = presenter
    }
}

```

## 自动注册的性能

App启动时会遍历所有的类，自动执行所有router的`registerRoutableDestination`方法。下面是自动注册的性能测试结果。

在测试项目中有5000个view controller，5000个view router。

用`+registerView:`和`registerViewProtocol:`注册：

* iPhone6s真机：58ms
* iPhone5真机：240ms

用`+ registerExclusiveView:`和`registerViewProtocol:`注册：

* iPhone6s真机：50ms
* iPhone5真机：220ms

在新机型上没有性能问题，在老机型上耗时会比较多，而大部分耗时都是在Objc的方法调用上，经测试，即便把注册方法都替换为空方法，耗时也是差不多的。

如果对性能问题有疑虑，可以关闭自动注册，使用分阶段的手动注册。不过目前还未支持。
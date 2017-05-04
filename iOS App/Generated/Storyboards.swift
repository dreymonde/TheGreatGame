// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation
import UIKit

// swiftlint:disable file_length
// swiftlint:disable line_length
// swiftlint:disable type_body_length

protocol StoryboardSceneType {
  static var storyboardName: String { get }
}

extension StoryboardSceneType {
  static func storyboard() -> UIStoryboard {
    return UIStoryboard(name: self.storyboardName, bundle: Bundle(for: BundleToken.self))
  }

  static func initialViewController() -> UIViewController {
    guard let vc = storyboard().instantiateInitialViewController() else {
      fatalError("Failed to instantiate initialViewController for \(self.storyboardName)")
    }
    return vc
  }
}

extension StoryboardSceneType where Self: RawRepresentable, Self.RawValue == String {
  func viewController() -> UIViewController {
    return Self.storyboard().instantiateViewController(withIdentifier: self.rawValue)
  }
  static func viewController(identifier: Self) -> UIViewController {
    return identifier.viewController()
  }
}

protocol StoryboardSegueType: RawRepresentable { }

extension UIViewController {
  func perform<S: StoryboardSegueType>(segue: S, sender: Any? = nil) where S.RawValue == String {
    performSegue(withIdentifier: segue.rawValue, sender: sender)
  }
}

struct ViewControllerResource<Scene : StoryboardSceneType, ViewController : UIViewController> where Scene : RawRepresentable, Scene.RawValue == String {

    fileprivate let scene: Scene

    func instantiate() -> ViewController {
        guard let vc = scene.viewController() as? ViewController
            else {
                fatalError("ViewController 'AddPointNavigationController' is not of the expected class The_Cleaning_App.NavigationController.")
        }
        return vc
    }

}

enum Storyboard {
  enum LaunchScreen: StoryboardSceneType {
    static let storyboardName = "LaunchScreen"
  }
  enum Main: String, StoryboardSceneType {
    static let storyboardName = "Main"

    static func initialViewController() -> TheGreatGame.NavigationController {
      guard let vc = storyboard().instantiateInitialViewController() as? TheGreatGame.NavigationController else {
        fatalError("Failed to instantiate initialViewController for \(self.storyboardName)")
      }
      return vc
    }

    case teamDetailViewControllerScene = "TeamDetailViewController"
    static var teamDetailViewController: ViewControllerResource<Main, TheGreatGame.TeamDetailViewController> {
      return ViewControllerResource(scene: .teamDetailViewControllerScene)
    }

    case teamsTableViewControllerScene = "TeamsTableViewController"
    static var teamsTableViewController: ViewControllerResource<Main, TheGreatGame.TeamsTableViewController> {
      return ViewControllerResource(scene: .teamsTableViewControllerScene)
    }
  }
}

enum StoryboardSegue {
  enum Main: String, StoryboardSegueType {
    case __Unused = "<#unused#>"
  }
}

private final class BundleToken {}


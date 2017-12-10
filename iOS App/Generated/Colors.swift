// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

#if os(OSX)
  import AppKit.NSColor
  typealias Color = NSColor
#elseif os(iOS) || os(tvOS) || os(watchOS)
  import UIKit.UIColor
  typealias Color = UIColor
#endif

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// swiftlint:disable operator_usage_whitespace
extension Color {
  convenience init(rgbaValue: UInt32) {
    let red   = CGFloat((rgbaValue >> 24) & 0xff) / 255.0
    let green = CGFloat((rgbaValue >> 16) & 0xff) / 255.0
    let blue  = CGFloat((rgbaValue >>  8) & 0xff) / 255.0
    let alpha = CGFloat((rgbaValue      ) & 0xff) / 255.0

    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}
// swiftlint:enable operator_usage_whitespace

// swiftlint:disable identifier_name line_length type_body_length
struct ColorName {
  let rgbaValue: UInt32
  var color: Color { return Color(named: self) }

  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#c0392b"></span>
  /// Alpha: 100% <br/> (0xc0392bff)
  static let errorMessageBackground = ColorName(rgbaValue: 0xc0392bff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#ffffcc"></span>
  /// Alpha: 100% <br/> (0xffffccff)
  static let favoriteBackground = ColorName(rgbaValue: 0xffffccff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#c05d5d"></span>
  /// Alpha: 100% <br/> (0xc05d5dff)
  static let navigationBackground = ColorName(rgbaValue: 0xc05d5dff)
  /// <span style="display:block;width:3em;height:2em;border:1px solid black;background:#27ae60"></span>
  /// Alpha: 100% <br/> (0x27ae60ff)
  static let onlineMessageBackground = ColorName(rgbaValue: 0x27ae60ff)
}
// swiftlint:enable identifier_name line_length type_body_length

extension Color {
  convenience init(named color: ColorName) {
    self.init(rgbaValue: color.rgbaValue)
  }
}

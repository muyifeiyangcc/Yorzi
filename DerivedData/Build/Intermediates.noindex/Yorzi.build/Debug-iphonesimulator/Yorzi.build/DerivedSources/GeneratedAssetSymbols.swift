import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "back" asset catalog image resource.
    static let back = ImageResource(name: "back", bundle: resourceBundle)

    /// The "camera" asset catalog image resource.
    static let camera = ImageResource(name: "camera", bundle: resourceBundle)

    /// The "lau" asset catalog image resource.
    static let lau = ImageResource(name: "lau", bundle: resourceBundle)

    /// The "login_bg" asset catalog image resource.
    static let loginBg = ImageResource(name: "login_bg", bundle: resourceBundle)

    /// The "tab1" asset catalog image resource.
    static let tab1 = ImageResource(name: "tab1", bundle: resourceBundle)

    /// The "tab1_sel" asset catalog image resource.
    static let tab1Sel = ImageResource(name: "tab1_sel", bundle: resourceBundle)

    /// The "tab2" asset catalog image resource.
    static let tab2 = ImageResource(name: "tab2", bundle: resourceBundle)

    /// The "tab2_sel" asset catalog image resource.
    static let tab2Sel = ImageResource(name: "tab2_sel", bundle: resourceBundle)

    /// The "tab3" asset catalog image resource.
    static let tab3 = ImageResource(name: "tab3", bundle: resourceBundle)

    /// The "tab3_sel" asset catalog image resource.
    static let tab3Sel = ImageResource(name: "tab3_sel", bundle: resourceBundle)

    /// The "tab4" asset catalog image resource.
    static let tab4 = ImageResource(name: "tab4", bundle: resourceBundle)

    /// The "tab4_sel" asset catalog image resource.
    static let tab4Sel = ImageResource(name: "tab4_sel", bundle: resourceBundle)

    /// The "tab5" asset catalog image resource.
    static let tab5 = ImageResource(name: "tab5", bundle: resourceBundle)

    /// The "tab5_sel" asset catalog image resource.
    static let tab5Sel = ImageResource(name: "tab5_sel", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "back" asset catalog image.
    static var back: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .back)
#else
        .init()
#endif
    }

    /// The "camera" asset catalog image.
    static var camera: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .camera)
#else
        .init()
#endif
    }

    /// The "lau" asset catalog image.
    static var lau: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lau)
#else
        .init()
#endif
    }

    /// The "login_bg" asset catalog image.
    static var loginBg: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .loginBg)
#else
        .init()
#endif
    }

    /// The "tab1" asset catalog image.
    static var tab1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tab1)
#else
        .init()
#endif
    }

    /// The "tab1_sel" asset catalog image.
    static var tab1Sel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tab1Sel)
#else
        .init()
#endif
    }

    /// The "tab2" asset catalog image.
    static var tab2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tab2)
#else
        .init()
#endif
    }

    /// The "tab2_sel" asset catalog image.
    static var tab2Sel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tab2Sel)
#else
        .init()
#endif
    }

    /// The "tab3" asset catalog image.
    static var tab3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tab3)
#else
        .init()
#endif
    }

    /// The "tab3_sel" asset catalog image.
    static var tab3Sel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tab3Sel)
#else
        .init()
#endif
    }

    /// The "tab4" asset catalog image.
    static var tab4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tab4)
#else
        .init()
#endif
    }

    /// The "tab4_sel" asset catalog image.
    static var tab4Sel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tab4Sel)
#else
        .init()
#endif
    }

    /// The "tab5" asset catalog image.
    static var tab5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tab5)
#else
        .init()
#endif
    }

    /// The "tab5_sel" asset catalog image.
    static var tab5Sel: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .tab5Sel)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "back" asset catalog image.
    static var back: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .back)
#else
        .init()
#endif
    }

    /// The "camera" asset catalog image.
    static var camera: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .camera)
#else
        .init()
#endif
    }

    /// The "lau" asset catalog image.
    static var lau: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .lau)
#else
        .init()
#endif
    }

    /// The "login_bg" asset catalog image.
    static var loginBg: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .loginBg)
#else
        .init()
#endif
    }

    /// The "tab1" asset catalog image.
    static var tab1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tab1)
#else
        .init()
#endif
    }

    /// The "tab1_sel" asset catalog image.
    static var tab1Sel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tab1Sel)
#else
        .init()
#endif
    }

    /// The "tab2" asset catalog image.
    static var tab2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tab2)
#else
        .init()
#endif
    }

    /// The "tab2_sel" asset catalog image.
    static var tab2Sel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tab2Sel)
#else
        .init()
#endif
    }

    /// The "tab3" asset catalog image.
    static var tab3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tab3)
#else
        .init()
#endif
    }

    /// The "tab3_sel" asset catalog image.
    static var tab3Sel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tab3Sel)
#else
        .init()
#endif
    }

    /// The "tab4" asset catalog image.
    static var tab4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tab4)
#else
        .init()
#endif
    }

    /// The "tab4_sel" asset catalog image.
    static var tab4Sel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tab4Sel)
#else
        .init()
#endif
    }

    /// The "tab5" asset catalog image.
    static var tab5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tab5)
#else
        .init()
#endif
    }

    /// The "tab5_sel" asset catalog image.
    static var tab5Sel: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .tab5Sel)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif
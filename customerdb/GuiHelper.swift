//
//  Gui Helper Class
//

import Foundation
import UIKit

class GuiHelper {
    private static var BORDER_WIDTH:CGFloat = 0.5
    private static var BORDER_RADIUS:CGFloat = 5
    private static var BORDER_COLOR_LIGHT = UIColor(
        red: 204.0 / 255.0,
        green: 204.0 / 255.0,
        blue: 204.0 / 255.0,
        alpha: CGFloat(1.0)
    ).cgColor
    private static var BORDER_COLOR_DARK = UIColor(
        red: 51.0 / 255.0,
        green: 51.0 / 255.0,
        blue: 51.0 / 255.0,
        alpha: CGFloat(1.0)
    ).cgColor
    
    // this function will optically adjust the UITextView, so that it looks like a UITextField
    static func adjustTextviewStyle(control:UITextView, viewController:UIViewController) {
        var backgroundColor = UIColor.white.cgColor
        var borderColor = GuiHelper.BORDER_COLOR_LIGHT
        if #available(iOS 12.0, *) {
            if viewController.traitCollection.userInterfaceStyle == .dark {
                borderColor = GuiHelper.BORDER_COLOR_DARK
                backgroundColor = UIColor.black.cgColor
            }
        }
        control.layer.borderColor = borderColor
        control.layer.borderWidth = GuiHelper.BORDER_WIDTH
        control.layer.cornerRadius = GuiHelper.BORDER_RADIUS
        control.layer.backgroundColor = backgroundColor
    }
    
    static func loadImage(file: URL) -> UIImage? {
        do {
            let imageData = try Data(contentsOf: file)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
}

class UITextFieldDatePicker: UIDatePicker {
    var textFieldReference:UITextField? = nil
}

extension UISearchBar {
    var textField : UITextField? {
        if #available(iOS 13.0, *) {
            return self.searchTextField
        } else {
            // fallback for earlier versions
            for view : UIView in (self.subviews[0]).subviews {
                if let textField = view as? UITextField {
                    return textField
                }
            }
        }
        return nil
    }
}

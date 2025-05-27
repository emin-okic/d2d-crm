//
//  Custom Field Class
//

import Foundation
import UIKit

class CustomField {
    
    //
    // These are the variables associated with a custom field object for the customer
    //
    var mId: Int64 = -1
    var mTitle: String = ""
    var mValue: String = ""
    var mType: Int = -1
    
    var mTextFieldHandle:UIView? = nil

    var mPresetPickerController:PickerDataController? = nil
    
    //
    // This defines all the types of objects a custom field can be
    //
    class TYPE {
        static var TEXT = 0
        static var NUMBER = 1
        static var DROPDOWN = 2
        static var DATE = 3
        static var TEXT_MULTILINE = 4
    }
    
    // This is how you initialize the custom field object initially
    init() {}
    
    //This is how you define a custom field later on with inputs
    init(title:String, value:String) {
        mTitle = title
        mValue = value
    }
    init(title:String, value:String, type:Int) {
        mTitle = title
        mValue = value
        mType = type
    }
    init(id:Int64, title:String, type:Int) {
        mId = id
        mTitle = title
        mType = type
    }
}

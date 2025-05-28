//
//  The Customer File Object
//

import Foundation

// The Customer File Model is dependent on the Customer Model existing first
class CustomerFile {
    
    //
    // This class defines what a customer file will hold
    //
    var mName = ""
    var mContent:Data? = nil

    //
    // This is how to construct a customer file object
    //
    init(name:String, content:Data) {
        mName = name
        mContent = content
    }
}

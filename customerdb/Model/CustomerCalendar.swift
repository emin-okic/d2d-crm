//
//  Customer Calendar Model
//

import Foundation

// This class defines what a customer calendar object looks like.
class CustomerCalendar {
    
    // A customer calendar should have an unique id.
    var mId:Int64 = -1
    
    // A customer calendar should have a title
    var mTitle = ""
    
    // A customer calendar should have a color
    var mColor = ""
    
    // There can be notes in the calendar
    var mNotes = ""
    
    // There can be a date when the calendar was last modified.
    var mLastModified = Date()
    
    // There should be a variable that lets me know if the event has been removed.
    var mRemoved = 0

    // You should be able to contruct a customer calendar out of nothing.
    init() {
        
    }
    
    // You should also be able to construct a non-empty customer calendar
    init(id:Int64, title:String, color:String, notes:String, lastModified:Date, removed:Int) {
        mId = id
        mTitle = title
        mColor = color
        mNotes = notes
        mLastModified = lastModified
        mRemoved = removed
    }
    
    // This function creates a unique id for the calendar object
    // This function has no inputs and returns a 64 bit integer as a result
    static func generateID() -> Int64 {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddkkmmss"
        let strId = dateFormatter.string(from: Date()) + String(Int.random(in: 1..<100))
        return Int64(strId) ?? -1
    }

    // This function modifies each attribute as needed on a calendar event object
    func putAttribute(key:String, value:String) {
        switch(key) {
            // This is what to do in the case of an id change
            case "id":
                mId = Int64(value) ?? -1; break
            
            // This is what to set the title to
            case "title":
                mTitle = value; break
            
            // This is what to set the calendar event object color to
            case "color":
                mColor = value; break
            case "notes":
                mNotes = value; break
            case "last_modified":
                if let lastMofified = CustomerDatabase.parseDate(strDate: value) {
                    mLastModified = lastMofified
                }
                break;
            case "removed":
                mRemoved = (value=="1" ? 1 : 0); break
            default:
                break
        }
    }

}

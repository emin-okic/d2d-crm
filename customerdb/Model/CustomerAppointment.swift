//
//  CustomerAppointment Class
//

// Import the foundation object
import Foundation

class CustomerAppointment {

    //
    // These are all the variables defining a customer appointment object
    //
    var mId:Int64 = -1
    var mCalendarId:Int64 = -1
    var mTitle = ""
    var mNotes = "";
    var mTimeStart:Date? = nil
    var mTimeEnd:Date? = nil
    var mFullday = false
    var mCustomer = ""
    var mCustomerId:Int64? = nil
    var mLocation = ""
    var mLastModified = Date()
    var mRemoved = 0
    var mColor = ""
    
    // This is one way to construct the customer appointment object
    init() {
        mId = Int64(Customer.generateID())
    }
    
    // This is another way to construct the customer appointment object
    init(id:Int64, calendarId:Int64, title:String, notes:String, timeStart:Date?, timeEnd:Date?, fullday:Bool, customer:String, customerId:Int64?, location:String, lastModified:Date, removed:Int) {
        mId = id
        mCalendarId = calendarId
        mTitle = title
        mNotes = notes
        mTimeStart = timeStart
        mTimeEnd = timeEnd
        mFullday = fullday
        mCustomer = customer
        mCustomerId = customerId
        mLocation = location
        mLastModified = lastModified
        mRemoved = removed
    }

    // This function generates a unique id for the object
    static func generateID() -> Int64 {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddkkmmss"
        let strId = dateFormatter.string(from: Date()) + String(Int.random(in: 1..<100))
        return Int64(strId) ?? -1
    }
    
    // This function also generates a unique id using the suffix as an input parameter
    static func generateID(suffix: Int) -> Int64 {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddkkmmss"
        let strId = dateFormatter.string(from: Date()) + String(suffix)
        return Int64(strId) ?? -1
    }

    // This function manages the attributes for a project
    func putAttribute(key:String, value:String) {
        switch(key) {
            case "id":
                mId = Int64(value) ?? -1; break
            case "calendar_id":
                mCalendarId = Int64(value) ?? -1; break
            case "title":
                mTitle = value; break
            case "notes":
                mNotes = value; break
            case "time_start":
                if let date = CustomerDatabase.parseDateRaw(strDate: value) {
                    mTimeStart = date
                }
                break;
            case "time_end":
                if let date = CustomerDatabase.parseDateRaw(strDate: value) {
                    mTimeEnd = date
                }
                break;
            case "fullday":
                mRemoved = (value=="1" ? 1 : 0); break
            case "customer":
                mCustomer = value; break
            case "customer_id":
                mCustomerId = Int64(value); break
            case "location":
                mLocation = value; break
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

    // This function gets the starting time of the calendar event object
    // This function returns an int which is equal to (hour x 60 minutes) + minutes from starting time
    func getStartTimeInMinutes() -> Int {
        let hour = Calendar.current.component(.hour, from: mTimeStart!)
        let min = Calendar.current.component(.minute, from: mTimeStart!)
        return (hour * 60) + min
    }
    
    // This function gets an ending time for the calendar event object
    // This function returns an int
    func getEndTimeInMinutes() -> Int {
        let hour = Calendar.current.component(.hour, from: mTimeEnd!)
        let min = Calendar.current.component(.minute, from: mTimeEnd!)
        return (hour * 60) + min
    }

}

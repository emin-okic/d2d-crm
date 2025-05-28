//
//  Customer Model
//

import Foundation
import UIKit

class Customer {
    
    //
    // These variables define the attributes of the Customer model object
    //
    var mId:Int64 = -1
    var mTitle = ""
    var mFirstName = ""
    var mLastName = ""
    var mPhoneHome = ""
    var mPhoneMobile = ""
    var mPhoneWork = ""
    var mEmail = ""
    var mStreet = ""
    var mZipcode = ""
    var mCity = ""
    var mCountry = ""
    var mBirthday:Date? = nil
    var mGroup = ""
    var mNewsletter = false
    var mNotes = ""
    var mCustomFields = ""

    var mImage:Data? = nil
    var mConsentImage:Data? = nil
    
    var mLastModified:Date = Date()
    var mRemoved = 0
    
    // This is one way to construct the Customer Model object
    // With one attribute -- a unique ID
    init() {
        mId = Int64(Customer.generateID())
    }
    
    // This is another way to construct a customer model object
    init(id:Int64, title:String, firstName:String, lastName:String, phoneHome:String, phoneMobile:String, phoneWork:String, email:String, street:String, zipcode:String, city:String, country:String, birthday:Date?, group:String, newsletter:Bool, notes:String, customFields:String, lastModified:Date, removed:Int) {
        mId = id
        mTitle = title
        mFirstName = firstName
        mLastName = lastName
        mPhoneHome = phoneHome
        mPhoneMobile = phoneMobile
        mPhoneWork = phoneWork
        mEmail = email
        mStreet = street
        mZipcode = zipcode
        mCity = city
        mCountry = country
        mBirthday = birthday
        mGroup = group
        mNewsletter = newsletter
        mNotes = notes
        mCustomFields = customFields
        mLastModified = lastModified
        mRemoved = removed
    }
    
    // Damn there is a third way to construct the customer model object
    init(id:Int64, title:String, firstName:String, lastName:String, phoneHome:String, phoneMobile:String, phoneWork:String, email:String, street:String, zipcode:String, city:String, country:String, birthday:Date?, group:String, newsletter:Bool, notes:String, customFields:String, image:Data?, consentImage:Data?, lastModified:Date, removed:Int) {
        mId = id
        mTitle = title
        mFirstName = firstName
        mLastName = lastName
        mPhoneHome = phoneHome
        mPhoneMobile = phoneMobile
        mPhoneWork = phoneWork
        mEmail = email
        mStreet = street
        mZipcode = zipcode
        mCity = city
        mCountry = country
        mBirthday = birthday
        mGroup = group
        mNewsletter = newsletter
        mNotes = notes
        mCustomFields = customFields
        mImage = image
        mConsentImage = consentImage
        mLastModified = lastModified
        mRemoved = removed
    }
    
    //
    // This function pretty much modifies all the properties that can be used in a Customer Model object
    //
    func putAttribute(key:String, value:String) {
        switch(key) {
        case "id":
            mId = Int64(value) ?? -1; break
        case "title":
            mTitle = value; break
        case "first_name":
            mFirstName = value; break
        case "last_name":
            mLastName = value; break
        case "phone_home":
            mPhoneHome = value; break
        case "phone_mobile":
            mPhoneMobile = value; break
        case "phone_work":
            mPhoneWork = value; break
        case "email":
            mEmail = value; break
        case "street":
            mStreet = value; break
        case "zipcode":
            mZipcode = value; break
        case "city":
            mCity = value; break
        case "country":
            mCountry = value; break
        case "birthday":
            if let birthday = CustomerDatabase.parseDateRaw(strDate: value) {
                mBirthday = birthday
            }
            break
        case "group", "customer_group":
            mGroup = value; break
        case "newsletter":
            mNewsletter = value=="1"; break
        case "notes":
            mNotes = value; break
        case "last_modified":
            if let lastMofified = CustomerDatabase.parseDate(strDate: value) {
                mLastModified = lastMofified
            }
            break
        case "removed":
            mRemoved = (value=="1" ? 1 : 0); break
        case "image":
            mImage = Data(base64Encoded: value, options: .ignoreUnknownCharacters); break
        case "custom_fields":
            mCustomFields = value; break
        case "files":
            do {
                if let filesData = value.data(using: .utf8, allowLossyConversion: false) {
                    if let jsonFiles = try JSONSerialization.jsonObject(with: filesData, options: []) as? [[String : Any]] {
                        for file in jsonFiles {
                            if let strName = file["name"] as? String, let strContent = file["content"] as? String {
                            }
                        }
                    }
                }
            } catch {}
            break
        default:
            setCustomField(title: key, value: value)
        }
    }
    
    //
    // This function generates a unique ID for the customer object
    //
    static func generateID() -> Int64 {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddkkmmss"
        let strId = dateFormatter.string(from: Date()) + String(Int.random(in: 1..<100))
        return Int64(strId) ?? -1
    }
    static func generateID(suffix: Int) -> Int64 {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddkkmmss"
        let strId = dateFormatter.string(from: Date()) + String(suffix)
        return Int64(strId) ?? -1
    }
    
    //
    // This function gets the full name of a customer
    //
    func getFullName(lastNameFirst:Bool) -> String {
        var final_title = ""
        if(mTitle != "") {
            final_title = mTitle+" "
        }

        var final_name = ""
        if(mLastName == "") { final_name = mFirstName }
        else if(mFirstName == "") { final_name = mLastName }
        else if(lastNameFirst) { final_name = mLastName + ", " + mFirstName }
        else { final_name = mFirstName + " " + mLastName }

        return final_title + final_name
    }
    
    func getFirstLine() -> String {
        return getFullName(lastNameFirst:true)
    }

    func getSecondLine() -> String {
        if(mPhoneHome != "") { return mPhoneHome }
        else if(mPhoneMobile != "") { return mPhoneMobile }
        else if(mPhoneWork != "") { return mPhoneWork }
        else if(mEmail != "") { return mEmail }
        else { return getFirstNotEmptyCustomFieldString() }
    }
    
    func getAddressString() -> String {
        return (mStreet + "\n" + mZipcode + " " + mCity + "\n" + mCountry)
                .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func getCustomFields() -> [CustomField] {
        var attributes:[CustomField] = []
        for urlEncodedAttribute in mCustomFields.components(separatedBy: "&") {
            let keyValuePair = urlEncodedAttribute.components(separatedBy: "=")
            if(keyValuePair.count != 2) { continue }
            let key = keyValuePair[0].stringByRemovingPercentEncoding() ?? ""
            let value = keyValuePair[1].stringByRemovingPercentEncoding() ?? ""
            if(key == "") { continue }
            attributes.append(CustomField(
                title: key, value: value
            ))
        }
        return attributes
    }
    func getCustomField(key:String) -> CustomField? {
        for field in getCustomFields() {
            if(field.mTitle == key) {
                return field
            }
        }
        return nil
    }
    func getCustomFieldString(key:String) -> String? {
        for field in getCustomFields() {
            if(field.mTitle == key) {
                if(field.mValue == "") {
                    return nil
                } else {
                    return field.mValue
                }
            }
        }
        return nil
    }
    func getFirstNotEmptyCustomFieldString() -> String {
        for field in getCustomFields() {
            if(field.mValue != "") {
                return field.mValue
            }
        }
        return ""
    }
    func setCustomFields(fields: [CustomField]) {
        var attributeString = ""
        for field in fields {
            if let titleEncoded = field.mTitle.stringByAddingPercentEncodingForRFC3986() {
                attributeString += titleEncoded
                attributeString += "="
                attributeString += field.mValue.stringByAddingPercentEncodingForRFC3986() ?? ""
                attributeString += "&"
            }
        }
        mCustomFields = attributeString
    }
    func setCustomField(title:String, value:String) {
        var fields = getCustomFields()
        for field in fields {
            if(field.mTitle == title) {
                field.mValue = value
                setCustomFields(fields: fields)
                return
            }
        }
        fields.append(CustomField(title: title, value: value))
        setCustomFields(fields: fields)
    }
    
    func getNextBirthday() -> Date? {
        if(mBirthday == nil) { return nil }
        
        let current = Date()
        
        let calendar = Calendar.current
        var dateComponents: DateComponents? = calendar.dateComponents([.year, .month, .day], from: mBirthday!)
        
        dateComponents?.year = calendar.component(.year, from: current)

        if(calendar.component(.month, from: mBirthday!) != calendar.component(.month, from: current)
            || calendar.component(.day, from: mBirthday!) != calendar.component(.day, from: current)) {
            // birthday is today - this is ok
            if(calendar.date(from: dateComponents!)!.timeIntervalSince1970 < current.timeIntervalSince1970) { // birthday this year is already in the past - go to next year
                dateComponents?.year = calendar.component(.year, from: current) + 1
            }
        }
        
        return calendar.date(from: dateComponents!)
    }
    
    func getBirthdayString() -> String {
        if(mBirthday == nil) { return "" }
        
        let calendar = Calendar.current
        let current = Date()
        let bday = mBirthday!
        
        var todayNote = ""
        if(calendar.component(.month, from: bday) == calendar.component(.month, from: current)
            && calendar.component(.day, from: bday) == calendar.component(.day, from: current)) {
            todayNote = " " + NSLocalizedString("today_note", comment: "")
        }
        
        return CustomerDatabase.dateToDisplayStringWithoutTime(date: bday) + todayNote
    }
}

extension String {
  func stringByAddingPercentEncodingForRFC3986() -> String? {
    let unreserved = "-._~/?"
    let allowed = NSMutableCharacterSet.alphanumeric()
    allowed.addCharacters(in: unreserved)
    return addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
  }
    func stringByRemovingPercentEncoding() -> String? {
        return replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }
}

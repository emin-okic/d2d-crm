//
//  Customer Database Controller
//

import Foundation
import SQLite3

class CustomerDatabase {
    
    // This defines the location to find the file to load
    static var DB_FILE = "customerdb.sqlite"
    
    // These essentially automates the process of creating my database.
    // Only if a connection exists but not database tables too
    static var CREATE_DB_STATEMENTS = [
        "CREATE TABLE IF NOT EXISTS customer (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR NOT NULL, first_name VARCHAR NOT NULL, last_name VARCHAR NOT NULL, phone_home VARCHAR NOT NULL, phone_mobile VARCHAR NOT NULL, phone_work VARCHAR NOT NULL, email VARCHAR NOT NULL, street VARCHAR NOT NULL, zipcode VARCHAR NOT NULL, city VARCHAR NOT NULL, country VARCHAR NOT NULL, birthday DATETIME, notes VARCHAR NOT NULL, customer_group VARCHAR NOT NULL, custom_fields VARCHAR NOT NULL, image BLOB, consent BLOB, last_modified DATETIME NOT NULL, removed INTEGER DEFAULT 0 NOT NULL);",
        "CREATE TABLE IF NOT EXISTS customer_extra_fields (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR UNIQUE NOT NULL, type INTEGER NOT NULL, last_modified DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL, removed INTEGER DEFAULT 0 NOT NULL);",
        "CREATE TABLE IF NOT EXISTS customer_extra_presets (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR NOT NULL, extra_field_id INTEGER NOT NULL);"
    ]
    
    var db: OpaquePointer?
    var mCallDirectoryExtensionDb = CallDirectoryDatabase()
    
    init() {
        let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(CustomerDatabase.DB_FILE)
        
        if(sqlite3_open(fileurl.path, &db) != SQLITE_OK) {
            print("error opening database "+fileurl.path)
        }
        for query in CustomerDatabase.CREATE_DB_STATEMENTS {
            if(sqlite3_exec(db, query, nil,nil,nil) != SQLITE_OK) {
                print("error creating table: "+String(cString: sqlite3_errmsg(db)!))
            }
        }
        upgradeDatabase()
    }
    
    func columnNotExists(table:String, column:String) -> Bool {
        var result = true
        var stmt:OpaquePointer?
        if(sqlite3_prepare(self.db, "PRAGMA table_info("+table+")", -1, &stmt, nil) == SQLITE_OK) {
            while sqlite3_step(stmt) == SQLITE_ROW {
                if(sqlite3_column_text(stmt, 1) != nil) {
                    let cString = String(cString: sqlite3_column_text(stmt, 1))
                    if(cString == column) {
                        result = false
                    }
                }
            }
        }
        return result
    }
    
    func upgradeDatabase() {
        if(columnNotExists(table: "customer_file", column: "content")) {
            let currentDateString = CustomerDatabase.dateToString(date: Date()) as NSString
            
            beginTransaction()
            sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS customer_file (id INTEGER PRIMARY KEY AUTOINCREMENT, customer_id INTEGER NOT NULL, name VARCHAR NOT NULL, content BLOB NOT NULL);", nil,nil,nil)
            
            var stmt:OpaquePointer?
            if(sqlite3_prepare(self.db, "SELECT id, consent FROM customer", -1, &stmt, nil) == SQLITE_OK) {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    var consent:Data? = nil
                    if let pointer = sqlite3_column_blob(stmt, 1) {
                        let length = Int(sqlite3_column_bytes(stmt, 1))
                        consent = Data(bytes: pointer, count: length)
                        var stmt2:OpaquePointer?
                        if sqlite3_prepare(self.db, "INSERT INTO customer_file (customer_id, name, content) VALUES (?, ?, ?)", -1, &stmt2, nil) == SQLITE_OK {
                            let name = NSLocalizedString("consent", comment: "")+".jpg" as NSString
                            sqlite3_bind_int64(stmt2, 1, sqlite3_column_int64(stmt, 0))
                            sqlite3_bind_text(stmt2, 2, name.utf8String, -1, nil)
                            if(consent == nil && consent!.count == 0) {
                                sqlite3_bind_null(stmt2, 3)
                            } else {
                                let tempData: NSMutableData = NSMutableData(length: 0)!
                                tempData.append(consent!)
                                sqlite3_bind_blob(stmt2, 3, tempData.bytes, Int32(tempData.length), nil)
                            }
                            if sqlite3_step(stmt2) == SQLITE_DONE {
                                sqlite3_finalize(stmt2)
                            }
                        }
                    }
                    var stmt2:OpaquePointer?
                    if sqlite3_prepare(self.db, "UPDATE customer SET consent = ?, last_modified = ? WHERE id = ?", -1, &stmt2, nil) == SQLITE_OK {
                        sqlite3_bind_null(stmt2, 1)
                        sqlite3_bind_text(stmt2, 2, currentDateString.utf8String, -1, nil)
                        sqlite3_bind_int64(stmt2, 3, sqlite3_column_int64(stmt, 0))
                        if sqlite3_step(stmt2) == SQLITE_DONE {
                            sqlite3_finalize(stmt2)
                        }
                    }
                }
            }
            commitTransaction()
        }
        
    }
    
    func updateCallDirectoryDatabase() {
        mCallDirectoryExtensionDb.truncateNumbers()
        for c in getCustomers(search: nil, showDeleted: false, withFiles: false) {
            mCallDirectoryExtensionDb.insertNumber(
                CallDirectoryNumber(
                    customerId: c.mId,
                    displayName: c.getFullName(lastNameFirst: false),
                    phoneNumber: c.mPhoneHome
                )
            )
            mCallDirectoryExtensionDb.insertNumber(
                CallDirectoryNumber(
                    customerId: c.mId,
                    displayName: c.getFullName(lastNameFirst: false),
                    phoneNumber: c.mPhoneMobile
                )
            )
            mCallDirectoryExtensionDb.insertNumber(
                CallDirectoryNumber(
                    customerId: c.mId,
                    displayName: c.getFullName(lastNameFirst: false),
                    phoneNumber: c.mPhoneWork
                )
            )
        }
    }
    
    func beginTransaction() {
        sqlite3_exec(self.db, "BEGIN EXCLUSIVE TRANSACTION", nil, nil, nil)
    }
    func commitTransaction() {
        sqlite3_exec(self.db, "COMMIT TRANSACTION", nil, nil, nil)
    }
    func rollbackTransaction() {
        sqlite3_exec(self.db, "ROLLBACK TRANSACTION", nil, nil, nil)
    }
    
    static var STORAGE_FORMAT = "yyyy-MM-dd HH:mm:ss"
    static var STORAGE_FORMAT_WITHOUT_TIME = "yyyy-MM-dd"
    static func dateToDisplayString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    static func dateToDisplayStringWithoutTime(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
    static func dateToString(date: Date?) -> String {
        var date2 = Date()
        if(date != nil) { date2 = date! }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CustomerDatabase.STORAGE_FORMAT
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: date2)
    }
    static func dateToStringRaw(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CustomerDatabase.STORAGE_FORMAT
        return dateFormatter.string(from: date)
    }
    static func dateToStringWithoutTimeRaw(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CustomerDatabase.STORAGE_FORMAT_WITHOUT_TIME
        return dateFormatter.string(from: date)
    }
    static func parseDisplayDateWithoutTime(strDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        return dateFormatter.date(from:strDate)
    }
    static func parseDate(strDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CustomerDatabase.STORAGE_FORMAT
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.date(from:strDate)
    }
    static func parseDateRaw(strDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CustomerDatabase.STORAGE_FORMAT
        return dateFormatter.date(from:strDate)
    }

    // Customer Operations
    func getCustomers(search:String?, showDeleted:Bool, withFiles:Bool, modifiedSince:Date?=nil) -> [Customer] {
        var customers:[Customer] = []
        var stmt:OpaquePointer?
        var sql = "SELECT id, title, first_name, last_name, phone_home, phone_mobile, phone_work, email, street, zipcode, city, country, birthday, customer_group, notes, custom_fields, last_modified, removed FROM customer WHERE removed = 0 ORDER BY last_name, first_name"
        if(showDeleted) {
            sql = "SELECT id, title, first_name, last_name, phone_home, phone_mobile, phone_work, email, street, zipcode, city, country, birthday, customer_group, notes, custom_fields, last_modified, removed FROM customer ORDER BY last_name, first_name"
        }
        if sqlite3_prepare(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                var birthday:Date? = nil
                if(sqlite3_column_text(stmt, 12) != nil) {
                    birthday = CustomerDatabase.parseDateRaw(strDate: String(cString: sqlite3_column_text(stmt, 12)))
                }
                var lastModified:Date = Date()
                if let date = CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 17))) {
                    lastModified = date
                }
                if(modifiedSince != nil && lastModified < modifiedSince!) {
                    continue
                }
                
                let c = Customer(
                    id: Int64(sqlite3_column_int64(stmt, 0)),
                    title: String(cString: sqlite3_column_text(stmt, 1)),
                    firstName: String(cString: sqlite3_column_text(stmt, 2)),
                    lastName: String(cString: sqlite3_column_text(stmt, 3)),
                    phoneHome: String(cString: sqlite3_column_text(stmt, 4)),
                    phoneMobile: String(cString: sqlite3_column_text(stmt, 5)),
                    phoneWork: String(cString: sqlite3_column_text(stmt, 6)),
                    email: String(cString: sqlite3_column_text(stmt, 7)),
                    street: String(cString: sqlite3_column_text(stmt, 8)),
                    zipcode: String(cString: sqlite3_column_text(stmt, 9)),
                    city: String(cString: sqlite3_column_text(stmt, 10)),
                    country: String(cString: sqlite3_column_text(stmt, 11)),
                    birthday: birthday,
                    group: String(cString: sqlite3_column_text(stmt, 13)),
                    notes: String(cString: sqlite3_column_text(stmt, 15)),
                    customFields: String(cString: sqlite3_column_text(stmt, 16)),
                    lastModified: lastModified,
                    removed: Int(sqlite3_column_int(stmt, 18))
                )
                
                if(search != nil && search != "") {
                    let normalizedSearch = search!.uppercased()
                    if(!c.mTitle.uppercased().contains(normalizedSearch)
                       && !c.mFirstName.uppercased().contains(normalizedSearch)
                       && !c.mLastName.uppercased().contains(normalizedSearch)
                       && !c.mPhoneHome.uppercased().contains(normalizedSearch)
                       && !c.mPhoneMobile.uppercased().contains(normalizedSearch)
                       && !c.mPhoneWork.uppercased().contains(normalizedSearch)
                       && !c.mEmail.uppercased().contains(normalizedSearch)
                       && !c.mStreet.uppercased().contains(normalizedSearch)
                       && !c.mZipcode.uppercased().contains(normalizedSearch)
                       && !c.mCity.uppercased().contains(normalizedSearch)
                       && !c.mGroup.uppercased().contains(normalizedSearch)
                       && !c.mNotes.uppercased().contains(normalizedSearch)
                       && !findInCustomFields(searchUpperCase: normalizedSearch, fields: c.getCustomFields())) {
                        continue
                    }
                }
                
                customers.append(c)
            }
        }
        
        if(withFiles) {
            var customersWithFiles:[Customer] = []
            return customersWithFiles
        }
        
        return customers
    }
    func findInCustomFields(searchUpperCase:String, fields:[CustomField]) -> Bool {
        for cf in fields {
            if(cf.mValue.uppercased().contains(searchUpperCase)) {
                return true
            }
        }
        return false
    }
    func getCustomerFiles(c: Customer) -> Customer {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "SELECT image FROM customer WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, c.mId)
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let pointer = sqlite3_column_blob(stmt, 0) {
                    let length = Int(sqlite3_column_bytes(stmt, 0))
                    c.mImage = Data(bytes: pointer, count: length)
                }
            }
        }
        
        return c
    }
    func getCustomer(id:Int64, showDeleted:Bool=false) -> Customer? {
        var customer:Customer? = nil
        var sql = "SELECT id, title, first_name, last_name, phone_home, phone_mobile, phone_work, email, street, zipcode, city, country, birthday, customer_group, notes, custom_fields, image, consent, last_modified, removed FROM customer WHERE id = ?"
        if(!showDeleted) {
            sql = sql + " AND removed = 0"
        }
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            while sqlite3_step(stmt) == SQLITE_ROW {
                var birthday:Date? = nil
                if(sqlite3_column_text(stmt, 12) != nil) {
                    birthday = CustomerDatabase.parseDateRaw(strDate: String(cString: sqlite3_column_text(stmt, 12)))
                }
                customer = (
                    Customer(
                        id: Int64(sqlite3_column_int64(stmt, 0)),
                        title: String(cString: sqlite3_column_text(stmt, 1)),
                        firstName: String(cString: sqlite3_column_text(stmt, 2)),
                        lastName: String(cString: sqlite3_column_text(stmt, 3)),
                        phoneHome: String(cString: sqlite3_column_text(stmt, 4)),
                        phoneMobile: String(cString: sqlite3_column_text(stmt, 5)),
                        phoneWork: String(cString: sqlite3_column_text(stmt, 6)),
                        email: String(cString: sqlite3_column_text(stmt, 7)),
                        street: String(cString: sqlite3_column_text(stmt, 8)),
                        zipcode: String(cString: sqlite3_column_text(stmt, 9)),
                        city: String(cString: sqlite3_column_text(stmt, 10)),
                        country: String(cString: sqlite3_column_text(stmt, 11)),
                        birthday: birthday,
                        group: String(cString: sqlite3_column_text(stmt, 13)),
                        notes: String(cString: sqlite3_column_text(stmt, 15)),
                        customFields: String(cString: sqlite3_column_text(stmt, 16)),
                        lastModified: CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 19))) ?? Date(),
                        removed: Int(sqlite3_column_int(stmt, 20))
                    )
                )
                // It seems this getCustomerFiles function is required to get prospect thumbnails.
                customer = getCustomerFiles(c: customer!)
            }
        }
        return customer
    }
    func updateCustomer(c: Customer, transact: Bool = true) -> Bool {
        if(transact) { beginTransaction() }
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "UPDATE customer SET title = ?, first_name = ?, last_name = ?, phone_home = ?, phone_mobile = ?, phone_work = ?, email = ?, street = ?, zipcode = ?, city = ?, country = ?, birthday = ?, notes = ?, customer_group = ?, custom_fields = ?, image = ?, consent = ?, last_modified = ? WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            let title = c.mTitle as NSString
            let firstName = c.mFirstName as NSString
            let lastName = c.mLastName as NSString
            let phoneHome = c.mPhoneHome as NSString
            let phoneMobile = c.mPhoneMobile as NSString
            let phoneWork = c.mPhoneWork as NSString
            let email = c.mEmail as NSString
            let street = c.mStreet as NSString
            let zipcode = c.mZipcode as NSString
            let city = c.mCity as NSString
            let country = c.mCountry as NSString
            let birthday:NSString? = (c.mBirthday==nil) ? nil : CustomerDatabase.dateToStringRaw(date: c.mBirthday!) as NSString
            let notes = c.mNotes as NSString
            let group = c.mGroup as NSString
            let customFields = c.mCustomFields as NSString
            let lastModified = CustomerDatabase.dateToString(date: c.mLastModified) as NSString
            sqlite3_bind_text(stmt, 1, title.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, firstName.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, lastName.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, phoneHome.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, phoneMobile.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, phoneWork.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 7, email.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 8, street.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 9, zipcode.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 10, city.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 11, country.utf8String, -1, nil)
            if(birthday == nil) {
                sqlite3_bind_null(stmt, 12)
            } else {
                sqlite3_bind_text(stmt, 12, birthday!.utf8String, -1, nil)
            }
            sqlite3_bind_text(stmt, 13, notes.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 15, group.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 16, customFields.utf8String, -1, nil)
            if(c.mImage == nil) {
                sqlite3_bind_null(stmt, 17)
            } else {
                let tempData: NSMutableData = NSMutableData(length: 0)!
                tempData.append(c.mImage!)
                sqlite3_bind_blob(stmt, 17, tempData.bytes, Int32(tempData.length), nil)
            }
            if(c.mConsentImage == nil) {
                sqlite3_bind_null(stmt, 18)
            } else {
                let tempData: NSMutableData = NSMutableData(length: 0)!
                tempData.append(c.mConsentImage!)
                sqlite3_bind_blob(stmt, 18, tempData.bytes, Int32(tempData.length), nil)
            }
            sqlite3_bind_text(stmt, 19, lastModified.utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 20, c.mId)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        
        if(transact) { commitTransaction() }
        return true
    }
    func insertCustomer(c: Customer, transact: Bool = true) -> Bool {
        if(c.mId == -1) {
            c.mId = Customer.generateID()
        }
        if(transact) { beginTransaction() }
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "INSERT INTO customer (id, title, first_name, last_name, phone_home, phone_mobile, phone_work, email, street, zipcode, city, country, birthday, notes, customer_group, custom_fields, image, consent, last_modified, removed) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", -1, &stmt, nil) == SQLITE_OK {
            let title = c.mTitle as NSString
            let firstName = c.mFirstName as NSString
            let lastName = c.mLastName as NSString
            let phoneHome = c.mPhoneHome as NSString
            let phoneMobile = c.mPhoneMobile as NSString
            let phoneWork = c.mPhoneWork as NSString
            let email = c.mEmail as NSString
            let street = c.mStreet as NSString
            let zipcode = c.mZipcode as NSString
            let city = c.mCity as NSString
            let country = c.mCountry as NSString
            let birthday:NSString? = (c.mBirthday==nil) ? nil : CustomerDatabase.dateToStringRaw(date: c.mBirthday!) as NSString
            let notes = c.mNotes as NSString
            let group = c.mGroup as NSString
            let customFields = c.mCustomFields as NSString
            let lastModified = CustomerDatabase.dateToString(date: c.mLastModified) as NSString
            sqlite3_bind_int64(stmt, 1, c.mId)
            sqlite3_bind_text(stmt, 2, title.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, firstName.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, lastName.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, phoneHome.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, phoneMobile.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 7, phoneWork.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 8, email.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 9, street.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 10, zipcode.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 11, city.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 12, country.utf8String, -1, nil)
            if(c.mBirthday == nil) {
                sqlite3_bind_null(stmt, 13)
            } else {
                sqlite3_bind_text(stmt, 13, birthday!.utf8String, -1, nil)
            }
            sqlite3_bind_text(stmt, 14, notes.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 16, group.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 17, customFields.utf8String, -1, nil)
            if(c.mImage == nil) {
                sqlite3_bind_null(stmt, 18)
            } else {
                let tempData: NSMutableData = NSMutableData(length: 0)!
                tempData.append(c.mImage!)
                sqlite3_bind_blob(stmt, 18, tempData.bytes, Int32(tempData.length), nil)
            }
            if(c.mConsentImage == nil) {
                sqlite3_bind_null(stmt, 19)
            } else {
                let tempData: NSMutableData = NSMutableData(length: 0)!
                tempData.append(c.mConsentImage!)
                sqlite3_bind_blob(stmt, 19, tempData.bytes, Int32(tempData.length), nil)
            }
            sqlite3_bind_text(stmt, 20, lastModified.utf8String, -1, nil)
            sqlite3_bind_int(stmt, 21, Int32(c.mRemoved))
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        if(transact) { commitTransaction() }
        return true
    }
    func removeCustomer(id: Int64, transact: Bool = true) {
        var stmt:OpaquePointer?
        if(transact) { beginTransaction() }
        if sqlite3_prepare(self.db, "UPDATE customer SET title = '', first_name = '', last_name = '', custom_fields = '', image = '', consent = '', last_modified = ?, removed = 1 WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            let lastModified = CustomerDatabase.dateToString(date: Date()) as NSString
            sqlite3_bind_text(stmt, 1, lastModified.utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 2, id)
            if sqlite3_step(stmt) == SQLITE_DONE { sqlite3_finalize(stmt) }
        }
        if sqlite3_prepare(self.db, "DELETE FROM customer_file WHERE customer_id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            if sqlite3_step(stmt) == SQLITE_DONE { sqlite3_finalize(stmt) }
        }
        if(transact) { commitTransaction() }
    }
    func deleteAllCustomers(transact: Bool = true) {
        if(transact) { beginTransaction() }
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "DELETE FROM customer WHERE 1=1", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        var stmt2:OpaquePointer?
        if sqlite3_prepare(self.db, "DELETE FROM customer_file WHERE 1=1", -1, &stmt2, nil) == SQLITE_OK {
            if sqlite3_step(stmt2) == SQLITE_DONE {
                sqlite3_finalize(stmt2)
            }
        }
        if(transact) { commitTransaction() }
    }
    
    // Custom Field Operations
    func getCustomFields() -> [CustomField] {
        var fields:[CustomField] = []
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "SELECT id, title, type FROM customer_extra_fields", -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                fields.append(
                    CustomField(
                        id: Int64(sqlite3_column_int(stmt, 0)),
                        title: String(cString: sqlite3_column_text(stmt, 1)),
                        type: Int(sqlite3_column_int(stmt, 2))
                    )
                )
            }
        }
        return fields
    }
    func getCustomField(id:Int) -> CustomField? {
        var customField:CustomField? = nil
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "SELECT id, title, type FROM customer_extra_fields WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            while sqlite3_step(stmt) == SQLITE_ROW {
                customField = (
                    CustomField(
                        id: Int64(sqlite3_column_int(stmt, 0)),
                        title: String(cString: sqlite3_column_text(stmt, 1)),
                        type: Int(sqlite3_column_int(stmt, 2))
                    )
                )
            }
        }
        return customField
    }
    func updateCustomField(cf: CustomField) -> Bool {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "UPDATE customer_extra_fields SET title = ?, type = ? WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            let title = cf.mTitle as NSString
            sqlite3_bind_text(stmt, 1, title.utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(cf.mType))
            sqlite3_bind_int64(stmt, 3, cf.mId)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        return true
    }
    func insertCustomField(cf: CustomField) -> Bool {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "INSERT INTO customer_extra_fields (title, type) VALUES (?,?)", -1, &stmt, nil) == SQLITE_OK {
            let key = cf.mTitle as NSString
            sqlite3_bind_text(stmt, 1, key.utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(cf.mType))
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        return true
    }
    func removeCustomField(id: Int64) {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "DELETE FROM customer_extra_fields WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
    }
    
    func getCustomFieldPresets(customFieldId: Int64) -> [CustomField] {
        var fields:[CustomField] = []
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "SELECT id, title FROM customer_extra_presets WHERE extra_field_id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, customFieldId)
            while sqlite3_step(stmt) == SQLITE_ROW {
                fields.append(
                    CustomField(
                        id: sqlite3_column_int64(stmt, 0),
                        title: String(cString: sqlite3_column_text(stmt, 1)),
                        type: -1
                    )
                )
            }
        }
        return fields
    }
    func insertCustomFieldPreset(fieldId: Int64, preset: String) -> Bool {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "INSERT INTO customer_extra_presets (title, extra_field_id) VALUES (?,?)", -1, &stmt, nil) == SQLITE_OK {
            let title = preset as NSString
            sqlite3_bind_text(stmt, 1, title.utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 2, fieldId)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        return true
    }
    func removeCustomFieldPreset(id: Int64) {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "DELETE FROM customer_extra_presets WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
    }
}

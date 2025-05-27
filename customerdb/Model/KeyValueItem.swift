import Foundation

// This defines a struct model which is a key value item
// A key value item has a key and value pair associated with it
// This is probably used to make key value pair arrays 
struct KeyValueItem: Codable {
    init(_ key: String, _ value: String) {
        self.key = key
        self.value = value
    }
    let key: String
    var value: String
}

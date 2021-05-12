import Foundation

struct DoorRequest: Codable {
    let openDoor : Bool

    enum CodingKeys: String, CodingKey {
        case openDoor
    }
}
import Foundation

struct CommunityPost: Identifiable {
    let id: String
//    let userId: String
    let username: String
    let message: String
    let timestamp: Date
}


struct Comment: Identifiable {
    var id: String
    var username: String
    var message: String
    var timestamp: Date
}

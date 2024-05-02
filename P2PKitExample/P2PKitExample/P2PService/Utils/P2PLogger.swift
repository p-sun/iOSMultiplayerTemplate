//
//  P2PLogger.swift
//  P2PKitExample
//
//  Created by Paige Sun on 4/26/24.
//

import OSLog

fileprivate let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "P2PLogger")

@inline(__always)
func prettyPrint(level: OSLogType = .info, _ message: String, file: String = #fileID, function: String = #function) {
    if P2PConstants.loggerEnabled {
        let fileName = NSURL(fileURLWithPath: file).deletingPathExtension?.lastPathComponent
        logger.log(level: level, "📒 \(fileName ?? file):\(function)\n\(message)")
    }
}

//@inline(__always)
//func prettyPrint(level: OSLogType = .info, _ items: Any..., file: String = #fileID, function: String = #function) {
//#if DEBUG
//    let fileName = NSURL(fileURLWithPath: file).deletingPathExtension?.lastPathComponent
//    let message = items.map {"\($0)"}.joined(separator: " ")
//    logger.log(level: .info, "📒 \(fileName ?? file):\(function)\n\(message)")
//#endif
//}

//
//  Logger.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 08/05/2023.
//

import Foundation

protocol LogDestination {
    func log(statement: String)

    func error(error: Error)
}

final class ConsoleLogDestination: LogDestination {
    func log(statement: String) {
        #if DEBUG
        print(statement)
        #endif
    }

    func error(error: Error) {
        #if DEBUG
        print(error)
        #endif
    }
}

final class Logger {
    private enum Level: CustomStringConvertible {
        case debug
        case info
        case verbose
        case warn
        case error
        case severe

        var description: String {
            switch self {
            case .debug:    return "💬 DEBUG"
            case .info:     return "ℹ️ INFO"
            case .verbose:  return "🔬 VERBOSE"
            case .warn:     return "⚠️ WARN"
            case .error:    return "‼️ ERROR"
            case .severe:   return "🔥 SEVERE"
            }
        }
    }

    // MARK: - State
    private static var dateFormatter : DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss"
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    // MARK: - Inputs

    private static let destinations: [LogDestination] = [ConsoleLogDestination()]


    // MARK: - Public
    static func debug(_ message: String, filePath: String = #file, line: Int = #line, functionName: String = #function) {
        log(event: .debug, message: message, filePath: filePath, line: line, functionName: functionName)
    }

    static func info(_ message: String, filePath: String = #file, line: Int = #line, functionName: String = #function) {
        log(event: .info, message: message, filePath: filePath, line: line, functionName: functionName)
    }

    static func verbose(_ message: String, filePath: String = #file, line: Int = #line, functionName: String = #function) {
        log(event: .verbose, message: message, filePath: filePath, line: line, functionName: functionName)
    }

    static func warn(_ message: String, filePath: String = #file, line: Int = #line, functionName: String = #function) {
        log(event: .warn, message: message, filePath: filePath, line: line, functionName: functionName)
    }
    static func error(_ message: String, error: Error? = nil, filePath: String = #file, line: Int = #line, functionName: String = #function) {
        log(event: .error, message: message, error: error, filePath: filePath, line: line, functionName: functionName)
    }

    static func severe(_ message: String, error: Error? = nil, filePath: String = #file, line: Int = #line, functionName: String = #function) {
        log(event: .severe, message: message, error: error, filePath: filePath, line: line, functionName: functionName)
    }

    // MARK: - Private
    private static func log(event: Level, message: String, error: Error? = nil, filePath: String, line: Int, functionName: String) {
        let statement = Logger.statement(event: event, message: message, filePath: filePath, line: line, functionName: functionName)

        for destination in destinations {
            destination.log(statement: statement)

            if let error = error {
                destination.error(error: error)
            }
        }
    }

    private static func statement(event: Level, message: String, filePath: String, line: Int, functionName: String) -> String {
        return [
            Logger.dateFormatter.string(from: Date()),
            event.description,
            Logger.functionCall(filePath: filePath, functionName: functionName, line: line),
            "-",
            message
        ].joined(separator: " ")
    }

    private static func functionCall(filePath: String, functionName: String, line: Int) -> String {
        return "\(fileName(path: filePath)).\(functionName):\(line)"
    }

    private static func fileName(path: String) -> String {
        return path
            .components(separatedBy: "/")
            .last?
            .components(separatedBy: ".")
            .first ?? ""
    }
}

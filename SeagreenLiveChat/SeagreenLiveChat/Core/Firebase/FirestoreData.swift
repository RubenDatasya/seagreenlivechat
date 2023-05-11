//
//  FirestoreData.swift
//  SeagreenLiveChat
//
//  Created by Ruben Mimoun on 11/05/2023.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift


class FirestoreData {
    private let type: FirestoreDataType
    private var collection: CollectionReference {
        Firestore.firestore().collection(type.rawValue)
    }

    enum FirestoreDataType: String {
        case pushtokens
        case chatChannel
        case attachment
        case conversation
        case message
        case media
        case user
        case event
        case participant
        case receivingStatus
        case medicalCase = "medicalcase"
    }

    init(_ type: FirestoreDataType) {
        self.type = type
    }

    func create<T>(id: String, model: Codable) async throws -> T where T: Codable {
        let reference = collection.document(id)
        try reference.setData(from: model)
        return try await reference.getDocument(as: T.self)
    }

    func createEntry<T>(model: Codable) async throws -> T where T: Codable {
        let reference = try collection.addDocument(from: model)
        return try await reference.getDocument(as: T.self)
    }

    func updateEntry<T>(id: String, model: Codable) async throws -> T where T: Codable {
        let reference = collection.document(id)
        try reference.setData(from: model)
        return try await reference.getDocument(as: T.self)
    }

    func getEntry<T: Codable>(id: String) async throws -> T where T: Codable {
        let reference = collection.document(id)
        return try await reference.getDocument(as: T.self)
    }

    func getEntry<T: Codable>(id: String, field: String) async throws -> T where T: Codable {
        let reference = try await collection.whereField(field, isEqualTo: id).getDocuments()
        if let model = try reference.documents.first?.data(as: T.self) {
            return model
        } else {
            throw FirebaseError.decodeError("id: \(id), field: \(field)")
        }
    }

    func getEntriesByDocIds<T: Codable>(ids: [String]) async throws -> [T] where T: Codable {
        guard !ids.isEmpty else { return [] }

        let data = try await collection.whereField(FieldPath.documentID(), in: ids).getDocuments()
        if data.documents.isEmpty {
            return []
        }
        return try data.documents.map { document in
            try document.data(as: T.self)
        }
    }

    func getEntries<T: Codable>(ids: [String], field: String, inArray: [String]) async throws -> [T] where T: Codable {
        guard !ids.isEmpty, !inArray.isEmpty else { return [] }

        let data = try await collection
            .whereField(FieldPath.documentID(), in: ids)
            .whereField(field, in: inArray)
            .getDocuments()
        if data.documents.isEmpty {
            return []
        }
        return try data.documents.map { document in
            try document.data(as: T.self)
        }
    }

    func getEntries<T: Codable>() async throws -> [T] where T: Codable {
        let data = try await collection.getDocuments()
        if data.documents.isEmpty {
            return []
        }

        return try data.documents.map { document in
            return try document.data(as: T.self)
        }
    }

    func getEntries<T: Codable>(field: String, isGreaterThan value: Any) async throws -> [T] where T: Codable {
        let data = try await collection
            .whereField(field, isGreaterThan: value)
            .getDocuments()

        if data.documents.isEmpty {
            return []
        }

        return try data.documents.map { document in
            return try document.data(as: T.self)
        }
    }

    func getEntries<T: Codable>(field: String, in array: [Any]) async throws -> [T] where T: Codable {
        guard !array.isEmpty else { return [] }

        let data = try await collection
            .whereField(field, in: array)
            .getDocuments()

        if data.documents.isEmpty {
            return []
        }

        return try data.documents.map { document in
            return try document.data(as: T.self)
        }
    }

    func getEntriesByField<T: Codable>(value: Any, field: String) async throws -> [T] where T: Codable {
        let data = try await collection.whereField(field, isEqualTo: value).getDocuments()
        if data.documents.isEmpty {
            return []
        }
        return try data.documents.map { document in
            try document.data(as: T.self)
        }
    }

    func getEntriesByIds<T: Codable>(field: String, ids: [String]) async throws -> [T] where T: Codable {
        guard !ids.isEmpty else { return [] }

        let data = try await collection.whereField(field, in: ids).getDocuments()
        if data.documents.isEmpty {
            return []
        }
        return try data.documents.map { document in
            try document.data(as: T.self)
        }
    }

    func getEntriesWhereInArray<T: Codable>(id: String, field: String) async throws -> [T] where T: Codable {
        let data = try await collection.whereField(field, arrayContains: id).getDocuments()
        if data.documents.isEmpty {
            return []
        }
        return try data.documents.map { document in
            try document.data(as: T.self)
        }
    }

    func getEntry<T: Codable>(value: String, field: String) async throws -> T? where T: Codable {
        let reference = try await collection.whereField(field, isEqualTo: value).getDocuments()
        return try reference.documents.first?.data(as: T.self)
    }

    func deleteEntry(id: String) async throws {
        let reference = collection.document(id)
        try await reference.delete()
    }

    func listen<T: Codable>(where field: String, value: String, onReceive: @escaping (([T]?, Error?) -> Void)) {
        collection.whereField(field, isEqualTo: value)
            .order(by: "time")
            .addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                onReceive(nil, error)
                return
            }

            do {
                let models = try documents.map { document in
                    try document.data(as: T.self)
                }
                onReceive(models, nil)
            } catch {
                onReceive(nil, error)
            }
        }
    }
}

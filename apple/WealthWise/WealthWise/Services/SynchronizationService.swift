//
//  SynchronizationService.swift
//  WealthWise
//
//  Created by GitHub Copilot on 2025-11-09.
//

import Foundation
import FirebaseFirestore

/// A centralized service to manage data synchronization between Firestore and the local Core Data store.
protocol SynchronizationService {
    /// Fetches changes from a specific Firestore collection since the last sync.
    /// - Parameters:
    ///   - collection: The Firestore collection to sync.
    ///   - lastSyncTimestamp: The timestamp of the last successful sync.
    /// - Returns: A collection of documents that have changed.
    func fetchUpdates(for collection: String, since lastSyncTimestamp: Timestamp) async throws -> [QueryDocumentSnapshot]

    /// Pushes a list of locally changed objects to Firestore.
    /// - Parameters:
    ///   - objects: An array of objects that conform to a local `Syncable` protocol.
    ///   - collection: The Firestore collection to update.
    func pushUpdates<T: Encodable>(_ objects: [T], to collection: String) async throws

    /// Resolves a conflict between a local and a remote version of an object.
    /// - Parameters:
    ///   - local: The local version of the object.
    ///   - remote: The remote data received from Firestore.
    /// - Returns: The merged and resolved object data.
    func resolveConflict(local: [String: Any], remote: [String: Any]) -> [String: Any]
}

class FirebaseSyncService: SynchronizationService {
    private let db = Firestore.firestore()

    func fetchUpdates(for collection: String, since lastSyncTimestamp: Timestamp) async throws -> [QueryDocumentSnapshot] {
        let query = db.collection(collection).whereField("updatedAt", isGreaterThan: lastSyncTimestamp)
        let snapshot = try await query.getDocuments()
        return snapshot.documents
    }

    func pushUpdates<T: Encodable>(_ objects: [T], to collection: String) async throws {
        let batch = db.batch()
        for object in objects {
            let docRef = db.collection(collection).document() // Or use a specific ID
            try batch.setData(from: object, for: docRef)
        }
        try await batch.commit()
    }

    func resolveConflict(local: [String: Any], remote: [String: Any]) -> [String: Any] {
        // Simple "last write wins" strategy based on timestamp.
        // A more sophisticated implementation could merge fields.
        guard let localDate = local["updatedAt"] as? Timestamp,
              let remoteDate = remote["updatedAt"] as? Timestamp else {
            // Default to remote if timestamps are missing
            return remote
        }
        return remoteDate > localDate ? remote : local
    }
}

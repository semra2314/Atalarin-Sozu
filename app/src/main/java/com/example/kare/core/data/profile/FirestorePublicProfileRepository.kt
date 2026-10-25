package com.example.kare.core.data.profile

import com.example.kare.core.model.PublicProfile
import com.example.kare.core.repository.PublicProfileRepository
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

/**
 * Production [PublicProfileRepository] implementation backed by Cloud Firestore.
 *
 * Persists and observes public user identity profiles (`profiles/{uid}`) in accordance
 * with the iOS Firestore reference schema.
 */
class FirestorePublicProfileRepository(
    private val firestore: FirebaseFirestore = FirebaseFirestore.getInstance(),
) : PublicProfileRepository {

    override fun observeProfile(uid: String): Flow<PublicProfile?> = callbackFlow {
        val docRef = firestore.collection(PROFILES_COLLECTION).document(uid)
        val registration = docRef.addSnapshotListener { snapshot, error ->
            if (error != null) {
                close(error)
                return@addSnapshotListener
            }

            if (snapshot != null && snapshot.exists()) {
                val profile = snapshot.toPublicProfile()
                trySend(profile)
            } else {
                trySend(null)
            }
        }

        awaitClose { registration.remove() }
    }

    override suspend fun getProfile(uid: String): PublicProfile? {
        return try {
            val snapshot = firestore.collection(PROFILES_COLLECTION).document(uid).get().await()
            if (snapshot.exists()) snapshot.toPublicProfile() else null
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            null
        }
    }

    override suspend fun putProfile(profile: PublicProfile) {
        val data = hashMapOf(
            "id" to profile.id,
            "displayName" to profile.displayName,
            "username" to profile.username,
            "updatedAt" to FieldValue.serverTimestamp(),
        )

        firestore.collection(PROFILES_COLLECTION)
            .document(profile.id)
            .set(data)
            .await()
    }

    private fun com.google.firebase.firestore.DocumentSnapshot.toPublicProfile(): PublicProfile {
        return PublicProfile(
            id = getString("id") ?: id,
            displayName = getString("displayName") ?: "",
            username = getString("username") ?: "",
            avatarData = null,
        )
    }

    private companion object {
        const val PROFILES_COLLECTION = "profiles"
    }
}

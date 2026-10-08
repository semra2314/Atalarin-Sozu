package com.example.kare.core.repository

/** Domain failures. ViewModels map them to localized messages; SDK exceptions stay behind repositories. */
sealed class RepositoryException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    class NotFound(val id: String) : RepositoryException("Item not found: $id")
    class Unavailable(val operation: String) : RepositoryException("Operation unavailable: $operation")
    class Unauthenticated : RepositoryException("Authentication required")
    class InvalidData(val field: String) : RepositoryException("Invalid data: $field")
    class Transport(cause: Throwable) : RepositoryException("Data source request failed", cause)
    class Persistence(cause: Throwable) : RepositoryException("Local persistence failed", cause)
}

package com.example.kare.core.model

/** Value-semantic image bytes corresponding to Swift Data, without exposing a mutable array. */
class ImageData(bytes: ByteArray) {
    private val bytes = bytes.copyOf()

    fun toByteArray(): ByteArray = bytes.copyOf()

    override fun equals(other: Any?): Boolean =
        other is ImageData && bytes.contentEquals(other.bytes)

    override fun hashCode(): Int = bytes.contentHashCode()

    override fun toString(): String = "ImageData(size=${bytes.size})"
}

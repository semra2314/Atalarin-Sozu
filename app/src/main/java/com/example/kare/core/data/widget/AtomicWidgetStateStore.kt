package com.example.kare.core.data.widget

import android.util.AtomicFile
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

/** Typed atomic-file mechanics shared by application-owned widget stores in the default process. */
open class AtomicWidgetStateStore<T>(private val directory: File, private val encode: (T) -> String, private val decode: (String) -> T) {
    private val lock = Mutex()
    private val revision = MutableStateFlow(0L)
    val changes = revision.asStateFlow()
    fun invalidate() { revision.update { it + 1 } }

    private fun file(id: Int): AtomicFile {
        require(id > 0) { "Invalid widget instance ID" }
        return AtomicFile(File(directory, "$id.json"))
    }
    suspend fun read(id: Int): T? = withContext(Dispatchers.IO) {
        lock.withLock {
            val file = file(id)
            if (!file.baseFile.exists() && !File(file.baseFile.path + ".bak").exists()) null
            else decode(file.openRead().bufferedReader().use { it.readText() })
        }
    }
    suspend fun save(id: Int, value: T) = withContext(Dispatchers.IO) {
        lock.withLock {
            require(directory.isDirectory || directory.mkdirs())
            val json = encode(value)
            val file = file(id)
            val stream = file.startWrite()
            try { stream.write(json.toByteArray(Charsets.UTF_8)); file.finishWrite(stream) }
            catch (error: Exception) { file.failWrite(stream); throw error }
            invalidate()
        }
    }
    suspend fun delete(id: Int) = withContext(Dispatchers.IO) {
        lock.withLock { file(id).delete(); invalidate() }
    }
}

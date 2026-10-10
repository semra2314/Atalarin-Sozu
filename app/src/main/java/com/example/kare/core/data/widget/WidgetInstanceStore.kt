package com.example.kare.core.data.widget

import android.util.AtomicFile
import com.example.kare.core.model.*
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.*

/** One application-owned store; all components run in the default app process. */
class WidgetInstanceStore(private val directory: File) {
    private val lock = Mutex()
    private val revision = MutableStateFlow(0L)
    val changes = revision.asStateFlow()
    fun invalidate() { revision.update { it + 1 } }

    private fun file(id: Int): AtomicFile {
        require(id > 0) { "Invalid widget instance ID" }
        return AtomicFile(File(directory, "$id.json"))
    }
    suspend fun read(id: Int): WidgetInstance? = withContext(Dispatchers.IO) {
        lock.withLock {
            val file = file(id)
            if (!file.baseFile.exists() && !File(file.baseFile.path + ".bak").exists()) null
            else decode(file.openRead().bufferedReader().use { it.readText() })
        }
    }
    suspend fun save(id: Int, value: WidgetInstance) = withContext(Dispatchers.IO) {
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
    companion object {
        fun encode(value: WidgetInstance): String {
            require(value.templateId == "t-proverb")
            return buildJsonObject {
                put("version", 1); put("templateId", value.templateId)
                put("selection", value.selection.name.lowercase())
            }.toString()
        }
        fun decode(json: String): WidgetInstance {
            val root = Json.parseToJsonElement(json).jsonObject
            require(root.getValue("version").jsonPrimitive.int == 1)
            require(root.getValue("templateId").jsonPrimitive.content == "t-proverb")
            val mode = ProverbSelection.entries.first { it.name.lowercase() == root.getValue("selection").jsonPrimitive.content }
            return WidgetInstance(selection = mode)
        }
    }
}

package com.example.kare.app

import com.example.kare.KareApplication
import com.example.kare.core.model.WidgetSize
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.SQLiteMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@SQLiteMode(SQLiteMode.Mode.NATIVE)
class AppContainerTest {
    @Test fun manifestApplicationOwnsStableDependenciesAndWorkingRepositories() = runBlocking {
        val application = RuntimeEnvironment.getApplication() as KareApplication
        val container = application.container
        try {
            assertSame(container, application.container)
            assertSame(container.widgets, container.widgets)
            assertSame(container.library, container.library)
            assertSame(container.database, container.database)
            assertSame(container.viewModelFactory, container.viewModelFactory)
            val template = container.widgets.template("p-sunset")
            val saved = container.library.install(template, WidgetSize.SMALL)
            assertEquals(template.content, saved.content)
            assertEquals(saved, container.library.widget(template.id))
            container.library.remove(template.id)
            Unit
        } finally { container.close() }
    }
}

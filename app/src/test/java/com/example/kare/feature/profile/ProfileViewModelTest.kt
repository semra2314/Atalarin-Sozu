package com.example.kare.feature.profile

import com.example.kare.core.data.auth.InMemoryAuthRepository
import com.example.kare.core.model.InstalledWidget
import com.example.kare.core.model.UserProfile
import com.example.kare.core.model.WidgetCategory
import com.example.kare.core.model.WidgetContent
import com.example.kare.core.model.WidgetSize
import com.example.kare.core.model.WidgetTemplate
import com.example.kare.core.repository.LibraryRepository
import com.example.kare.core.repository.ProfileRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.time.Instant

@OptIn(ExperimentalCoroutinesApi::class)
class ProfileViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var authRepository: InMemoryAuthRepository
    private lateinit var fakeLibraryRepository: FakeLibraryRepository
    private lateinit var fakeProfileRepository: FakeProfileRepository
    private lateinit var viewModel: ProfileViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        authRepository = InMemoryAuthRepository()
        fakeLibraryRepository = FakeLibraryRepository()
        fakeProfileRepository = FakeProfileRepository()
        viewModel = ProfileViewModel(fakeProfileRepository, fakeLibraryRepository, authRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun guestState_reflectsCorrectly() = runTest {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.uiState.collect() }
        testDispatcher.scheduler.advanceUntilIdle()
        assertTrue(viewModel.uiState.value.isGuest)

        authRepository.register("Test User", "user@example.com", "validPass1")
        testDispatcher.scheduler.advanceUntilIdle()
        assertFalse(viewModel.uiState.value.isGuest)
    }

    @Test
    fun widgetStats_calculatedAccurately() = runTest {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.uiState.collect() }
        fakeLibraryRepository.setWidgets(
            listOf(
                sampleWidget("w1", isFavorite = true),
                sampleWidget("w2", isFavorite = false),
            )
        )
        testDispatcher.scheduler.advanceUntilIdle()

        assertEquals(2, viewModel.uiState.value.widgetCount)
        assertEquals(1, viewModel.uiState.value.favoritesCount)
        assertEquals(1, viewModel.uiState.value.favoriteWidgets.size)
    }

    @Test
    fun toggleFavorite_invertsFavoriteStatus() = runTest {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.uiState.collect() }
        val widget = sampleWidget("w1", isFavorite = false)
        fakeLibraryRepository.setWidgets(listOf(widget))
        testDispatcher.scheduler.advanceUntilIdle()

        viewModel.toggleFavorite(widget)
        testDispatcher.scheduler.advanceUntilIdle()

        assertTrue(fakeLibraryRepository.isFavorite("w1"))
    }

    private fun sampleWidget(id: String, isFavorite: Boolean) = InstalledWidget(
        templateId = id,
        name = "Widget $id",
        authorName = "Author",
        size = WidgetSize.MEDIUM,
        category = WidgetCategory.MINIMAL,
        isFavorite = isFavorite,
    )

    private class FakeProfileRepository : ProfileRepository {
        private val _profile = MutableStateFlow(UserProfile(displayName = "Test User", username = "tester"))
        override val profile: StateFlow<UserProfile> = _profile

        override suspend fun updateProfile(
            displayName: String,
            username: String,
            avatarPath: String?,
        ): Result<Unit> {
            _profile.value = _profile.value.copy(
                displayName = displayName,
                username = username,
                avatarPath = avatarPath,
            )
            return Result.success(Unit)
        }

        override suspend fun refresh() {}
    }

    private class FakeLibraryRepository : LibraryRepository {
        private val _installed = MutableStateFlow<List<InstalledWidget>>(emptyList())
        override fun observeWidgets(): Flow<List<InstalledWidget>> = _installed

        override suspend fun widget(templateId: String): InstalledWidget? =
            _installed.value.firstOrNull { it.templateId == templateId }

        fun setWidgets(list: List<InstalledWidget>) {
            _installed.value = list
        }

        fun isFavorite(id: String): Boolean =
            _installed.value.firstOrNull { it.templateId == id }?.isFavorite == true

        override suspend fun install(template: WidgetTemplate, size: WidgetSize): InstalledWidget {
            val installed = InstalledWidget(
                templateId = template.id,
                name = template.name,
                authorName = template.author.displayName,
                category = template.category,
                size = size,
            )
            _installed.value = _installed.value + installed
            return installed
        }

        override suspend fun remove(templateId: String): InstalledWidget? {
            val item = _installed.value.firstOrNull { it.templateId == templateId }
            _installed.value = _installed.value.filter { it.templateId != templateId }
            return item
        }

        override suspend fun setFavorite(templateId: String, isFavorite: Boolean) {
            _installed.value = _installed.value.map {
                if (it.templateId == templateId) it.copy(isFavorite = isFavorite) else it
            }
        }

        override suspend fun updateContent(templateId: String, content: WidgetContent) {}

        override suspend fun reorder(templateIds: List<String>) {}
    }
}

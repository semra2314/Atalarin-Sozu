package com.example.kare.navigation

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hasRoute
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.*
import androidx.navigation.toRoute
import com.example.kare.R
import com.example.kare.core.design.*
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.feature.auth.*
import com.example.kare.feature.detail.DetailRoute
import com.example.kare.core.ui.ScreenTitle
import com.example.kare.feature.discover.*
import com.example.kare.feature.library.*
import com.example.kare.feature.search.*
import kotlinx.serialization.Serializable

sealed interface KareDestination {
    @Serializable data object Discover : KareDestination
    @Serializable data object Library : KareDestination
    @Serializable data object Search : KareDestination
    @Serializable data object Profile : KareDestination
    @Serializable data object Settings : KareDestination
    @Serializable data object SignIn : KareDestination
    @Serializable data object SignUp : KareDestination
    @Serializable data class Detail(val templateId: String) : KareDestination
}
private data class MainDestination(val route: KareDestination, val title: Int, val icon: ImageVector)
private val mainDestinations = listOf(
    MainDestination(KareDestination.Discover, R.string.discover_title, Icons.Default.Home),
    MainDestination(KareDestination.Library, R.string.library_title, Icons.Default.Favorite),
    MainDestination(KareDestination.Search, R.string.search_title, Icons.Default.Search),
    MainDestination(KareDestination.Profile, R.string.profile_title, Icons.Default.Person),
    MainDestination(KareDestination.Settings, R.string.settings_title, Icons.Default.Settings),
)

@Composable
fun KareApp(factory: ViewModelProvider.Factory, navController: NavHostController = rememberNavController()) {
    val current by navController.currentBackStackEntryAsState()
    val isDetail = current?.destination?.hasRoute<KareDestination.Detail>() == true
    val isAuth = current?.destination?.hasRoute<KareDestination.SignIn>() == true ||
        current?.destination?.hasRoute<KareDestination.SignUp>() == true
    val hideBottomBar = isDetail || isAuth

    Scaffold(bottomBar = {
        if (!hideBottomBar) NavigationBar {
            mainDestinations.forEach { destination ->
                NavigationBarItem(selected = current?.destination?.hasRoute(destination.route::class) == true,
                    onClick = {
                        navController.navigate(destination.route) {
                            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                            launchSingleTop = true
                            restoreState = true
                        }
                    }, icon = { Icon(destination.icon, contentDescription = null) },
                    label = { Text(stringResource(destination.title)) },
                    modifier = Modifier.testTag("nav-${destination.title}"))
            }
        }
    }) { padding ->
        NavHost(navController, startDestination = KareDestination.Discover,
            modifier = Modifier.padding(padding).consumeWindowInsets(padding).imePadding()) {
            composable<KareDestination.Discover> {
                DiscoverRoute(viewModel(factory = factory)) { navController.navigate(KareDestination.Detail(it)) }
            }
            composable<KareDestination.Library> {
                LibraryRoute(viewModel(factory = factory)) { navController.navigate(KareDestination.Detail(it)) }
            }
            composable<KareDestination.Search> {
                SearchRoute(viewModel(factory = factory)) { navController.navigate(KareDestination.Detail(it)) }
            }
            composable<KareDestination.Profile> {
                PendingContent(
                    title = R.string.profile_title,
                    onSignInClick = { navController.navigate(KareDestination.SignIn) }
                )
            }
            composable<KareDestination.Settings> { PendingContent(R.string.settings_title) }
            composable<KareDestination.SignIn> {
                SignInRoute(
                    viewModel = viewModel(factory = factory),
                    onNavigateToSignUp = { navController.navigate(KareDestination.SignUp) },
                    onSignInSuccess = { navController.popBackStack() },
                    onBack = { navController.popBackStack() }
                )
            }
            composable<KareDestination.SignUp> {
                SignUpRoute(
                    viewModel = viewModel(factory = factory),
                    onNavigateToSignIn = {
                        navController.navigate(KareDestination.SignIn) {
                            popUpTo(KareDestination.SignUp) { inclusive = true }
                        }
                    },
                    onSignUpSuccess = { navController.popBackStack() },
                    onBack = { navController.popBackStack() }
                )
            }
            composable<KareDestination.Detail> {
                DetailRoute(viewModel(factory = factory), onBack = { navController.popBackStack() }, onLibrary = {
                    navController.popBackStack()
                    navController.navigate(KareDestination.Library) {
                        popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                        launchSingleTop = true
                        restoreState = true
                    }
                })
            }
        }
    }
}

@Composable
private fun PendingContent(title: Int, onSignInClick: (() -> Unit)? = null) {
    Column(Modifier.fillMaxSize().padding(KareSpacing.lg), verticalArrangement = Arrangement.spacedBy(KareSpacing.lg)) {
        ScreenTitle(stringResource(title))
        Text(stringResource(R.string.feature_pending))
        if (title == R.string.profile_title && onSignInClick != null) {
            Spacer(Modifier.height(KareSpacing.sm))
            AuthButton(
                text = stringResource(R.string.auth_sign_in_action),
                onClick = onSignInClick,
                testTag = "profile-go-to-sign-in"
            )
        }
    }
}

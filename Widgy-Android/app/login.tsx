import { Ionicons } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

export default function LoginScreen() {
  const router = useRouter();

  // Navigates directly to the main application.
  // This is currently used as a placeholder until authentication is implemented.
  const finishLogin = () => {
    router.replace("/(tabs)");
  };

  // Placeholder for the future Google authentication flow.
  const handleGoogleLogin = () => {
    console.log("Starting Google authentication...");
    // finishLogin(); // Enable once the authentication flow is implemented.
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Branding and introductory content */}
      <View style={styles.topContainer}>
        <View style={styles.logoContainer}>
          <Text style={styles.logoText}>widgy</Text>
          <View style={styles.redDot} />
        </View>

        <Text style={styles.title}>Create your account</Text>
        <Text style={styles.subtitle}>
          Sign in once so your widgets and library follow you everywhere.
        </Text>
      </View>

      {/* Authentication actions */}
      <View style={styles.bottomContainer}>
        {/* Google sign-in button */}
        <TouchableOpacity
          style={[styles.button, styles.googleButton]}
          activeOpacity={0.8}
          onPress={handleGoogleLogin}
        >
          <Ionicons
            name="logo-google"
            size={20}
            color="#fff"
            style={styles.icon}
          />
          <Text style={styles.googleButtonText}>Sign in with Google</Text>
        </TouchableOpacity>

        {/* Email registration button */}
        <TouchableOpacity
          style={[styles.button, styles.emailButton]}
          activeOpacity={0.8}
        >
          <Text style={styles.emailButtonText}>Sign up with email</Text>
        </TouchableOpacity>

        {/* Existing account login */}
        <View style={styles.loginLinkContainer}>
          <Text style={styles.loginText}>Already have an account? </Text>
          <TouchableOpacity onPress={finishLogin}>
            <Text style={styles.loginTextBold}>Log in</Text>
          </TouchableOpacity>
        </View>

        {/* Allows users to continue without signing in */}
        <TouchableOpacity onPress={finishLogin}>
          <Text style={styles.continueText}>Continue without account</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  // Screen layout
  container: {
    flex: 1,
    backgroundColor: "#FAFAFA",
    justifyContent: "space-between",
  },

  // Upper section containing branding and onboarding text
  topContainer: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 30,
    marginTop: 60,
  },

  // Application logo
  logoContainer: {
    flexDirection: "row",
    alignItems: "baseline",
    marginBottom: 40,
  },

  logoText: {
    fontSize: 48,
    fontWeight: "900",
    color: "#1A1A1A",
    letterSpacing: -1.5,
  },

  redDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: "#d65a42",
    marginLeft: 2,
    marginBottom: 35,
  },

  // Welcome text
  title: {
    fontSize: 24,
    fontWeight: "800",
    color: "#1A1A1A",
    marginBottom: 12,
  },

  subtitle: {
    fontSize: 14,
    color: "#757575",
    textAlign: "center",
    lineHeight: 20,
  },

  // Lower section containing authentication actions
  bottomContainer: {
    paddingHorizontal: 24,
    paddingBottom: 40,
    width: "100%",
    alignItems: "center",
  },

  // Base button style shared by all authentication buttons
  button: {
    width: "100%",
    paddingVertical: 18,
    borderRadius: 30,
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 16,
  },

  // Primary Google authentication button
  googleButton: {
    backgroundColor: "#000000",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 3,
    elevation: 2,
  },

  googleButtonText: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "700",
  },

  // Google icon spacing
  icon: {
    marginRight: 8,
    marginBottom: 2,
  },

  // Secondary email registration button
  emailButton: {
    backgroundColor: "#FFFFFF",
    borderWidth: 1,
    borderColor: "#E0E0E0",
  },

  emailButtonText: {
    color: "#1A1A1A",
    fontSize: 16,
    fontWeight: "600",
  },

  // Login link section
  loginLinkContainer: {
    flexDirection: "row",
    marginTop: 20,
    marginBottom: 16,
  },

  loginText: {
    color: "#757575",
    fontSize: 14,
  },

  loginTextBold: {
    color: "#d65a42",
    fontSize: 14,
    fontWeight: "600",
  },

  // Guest access option
  continueText: {
    color: "#9E9E9E",
    fontSize: 13,
    fontWeight: "500",
  },
});

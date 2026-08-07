import { useRouter } from "expo-router";
import React, { useState } from "react";
import {
  Image,
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

// Onboarding content displayed across the introductory screens.
const slides = [
  {
    id: 1,
    title: "Ready-made widgets, beautifully done",
    subtitle:
      "Experience the ease of professional customization with our curated collection of widgets designed for your home screen.",
    image: require("../assets/images/icon-widgy.png"), // Replace with the final illustration.
  },
  {
    id: 2,
    title: "Make them yours",
    subtitle:
      "Change the text, colours, fonts and stickers. Add your own photo in a tap.",
    image: require("../assets/images/icon-widgy.png"), // Replace with the final illustration.
  },
  {
    id: 3,
    title: "On your home screen in seconds",
    subtitle: "Design it, save it, and add it straight to your home screen.",
    image: require("../assets/images/icon-widgy.png"), // Replace with the final illustration.
  },
];

export default function OnboardingScreen() {
  const router = useRouter();
  const [currentIndex, setCurrentIndex] = useState(0);

  // Currently displayed onboarding slide.
  const currentSlide = slides[currentIndex];

  // Determines whether the user is viewing the final onboarding screen.
  const isLastSlide = currentIndex === slides.length - 1;

  // Advances to the next slide or navigates to the authentication flow.
  const handleNext = () => {
    if (isLastSlide) {
      router.replace("/login");
    } else {
      setCurrentIndex(currentIndex + 1);
    }
  };

  // Skips onboarding and navigates directly to the authentication flow.
  const handleSkip = () => {
    router.replace("/login");
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Skip action */}
      <View style={styles.header}>
        <TouchableOpacity onPress={handleSkip}>
          <Text style={styles.skipText}>Skip</Text>
        </TouchableOpacity>
      </View>

      {/* Current onboarding illustration */}
      <View style={styles.imageContainer}>
        <Image
          source={currentSlide.image}
          style={styles.image}
          resizeMode="contain"
        />
      </View>

      {/* Current onboarding content */}
      <View style={styles.textContainer}>
        <Text style={styles.title}>{currentSlide.title}</Text>
        <Text style={styles.subtitle}>{currentSlide.subtitle}</Text>
      </View>

      {/* Navigation controls */}
      <View style={styles.footer}>
        {/* Progress indicator */}
        <View style={styles.paginationContainer}>
          {slides.map((_, index) => (
            <View
              key={index}
              style={[styles.dot, currentIndex === index && styles.activeDot]}
            />
          ))}
        </View>

        {/* Primary navigation button */}
        <TouchableOpacity
          style={styles.button}
          onPress={handleNext}
          activeOpacity={0.8}
        >
          <Text style={styles.buttonText}>
            {isLastSlide ? "Get Started" : "Next"}
          </Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  // Root screen layout.
  container: {
    flex: 1,
    backgroundColor: "#FAFAFA",
  },

  // Top navigation area.
  header: {
    width: "100%",
    alignItems: "flex-end",
    paddingHorizontal: 24,
    paddingTop: Platform.OS === "android" ? 40 : 10,
  },

  // Skip action.
  skipText: {
    fontSize: 16,
    color: "#9E9E9E",
    fontWeight: "500",
  },

  // Illustration container.
  imageContainer: {
    flex: 1.5,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 20,
  },

  image: {
    width: "100%",
    height: "100%",
  },

  // Slide content.
  textContainer: {
    flex: 1,
    paddingHorizontal: 24,
    justifyContent: "flex-start",
  },

  title: {
    fontSize: 32,
    fontWeight: "800",
    color: "#1A1A1A",
    marginBottom: 16,
  },

  subtitle: {
    fontSize: 15,
    color: "#757575",
    lineHeight: 22,
  },

  // Bottom navigation area.
  footer: {
    paddingHorizontal: 24,
    paddingBottom: 40,
    alignItems: "center",
  },

  // Pagination indicator.
  paginationContainer: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 30,
  },

  dot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: "#E0E0E0",
    marginHorizontal: 4,
  },

  activeDot: {
    width: 20,
    backgroundColor: "#d65a42",
  },

  // Primary call-to-action button.
  button: {
    backgroundColor: "#d65a42",
    width: "100%",
    paddingVertical: 18,
    borderRadius: 30,
    alignItems: "center",
  },

  buttonText: {
    color: "#FFFFFF",
    fontSize: 16,
    fontWeight: "600",
  },
});

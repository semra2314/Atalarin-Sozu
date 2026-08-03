import React from "react";
import {
  ImageBackground,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

export default function HeroCard() {
  return (
    <TouchableOpacity activeOpacity={0.9} style={styles.cardContainer}>
      <ImageBackground
        source={{
          uri: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=600",
        }}
        style={styles.imageBackground}
        imageStyle={styles.imageRadius}
      >
        {/* Content overlay displayed on top of the background image */}
        <View style={styles.overlay}>
          <View style={styles.badge}>
            <Text style={styles.badgeText}>WIDGET OF THE DAY</Text>
          </View>

          <Text style={styles.title}>Ethereal Flux v.2</Text>
          <Text style={styles.author}>by Julian Void</Text>
        </View>
      </ImageBackground>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  // Main card container
  cardContainer: {
    marginHorizontal: 20,
    marginVertical: 12,
    backgroundColor: "#fff",
    borderRadius: 24,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.08,
    shadowRadius: 12,
    elevation: 4,
  },

  // Background image
  imageBackground: {
    width: "100%",
    height: 220,
    justifyContent: "flex-end",
  },

  imageRadius: {
    borderRadius: 24,
  },

  // Bottom overlay for text content
  overlay: {
    padding: 20,
    backgroundColor: "rgba(0, 0, 0, 0.1)",
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
  },

  // Highlight badge
  badge: {
    backgroundColor: "#d65a42",
    alignSelf: "flex-start",
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 20,
    marginBottom: 6,
  },

  badgeText: {
    color: "#fff",
    fontSize: 9,
    fontWeight: "700",
    letterSpacing: 0.5,
  },

  title: {
    color: "#fff",
    fontSize: 26,
    fontWeight: "600",
  },

  author: {
    color: "rgba(255, 255, 255, 0.85)",
    fontSize: 13,
  },
});

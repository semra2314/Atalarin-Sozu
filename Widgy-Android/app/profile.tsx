import { Ionicons } from "@expo/vector-icons";
import React from "react";
import {
  Image,
  ImageBackground,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

// Sample data for the widget grid
const MY_WIDGETS = [
  {
    id: "1",
    title: "CHRONOS v2",
    category: "Minimalist Clock",
    icon: "time-outline",
    liked: false,
  },
  {
    id: "2",
    title: "ATMOS",
    category: "Weather Flow",
    icon: "thermometer-outline",
    liked: false,
  },
  {
    id: "3",
    title: "AGENDA",
    category: "Daily Focus",
    icon: "calendar-outline",
    liked: true,
  },
  {
    id: "4",
    title: "ENERGIA",
    category: "Battery Status",
    icon: "flash-outline",
    liked: false,
  },
];

export default function ProfileScreen() {
  return (
    <SafeAreaView style={styles.container} edges={["top", "left", "right"]}>
      {/* Screen header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Profile</Text>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* Profile section */}
        <View style={styles.avatarSection}>
          <View style={styles.avatarContainer}>
            <Image
              source={{
                uri: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300",
              }}
              style={styles.mainAvatar}
            />

            {/* Verified badge */}
            <View style={styles.verifiedBadge}>
              <Ionicons name="checkmark-circle" size={18} color="#fff" />
            </View>
          </View>

          <Text style={styles.profileName}>Julianne V.</Text>
          <Text style={styles.profileHandle}>@julianne_des_01</Text>
        </View>

        {/* User statistics */}
        <View style={styles.statsContainer}>
          <View style={styles.statBox}>
            <Text style={styles.statNumber}>12</Text>
            <Text style={styles.statLabel}>WIDGETS</Text>
          </View>

          <View style={styles.divider} />

          <View style={styles.statBox}>
            <Text style={styles.statNumber}>482</Text>
            <Text style={styles.statLabel}>FOLLOWING</Text>
          </View>

          <View style={styles.divider} />

          <View style={styles.statBox}>
            <Text style={styles.statNumber}>1.2k</Text>
            <Text style={styles.statLabel}>FOLLOWERS</Text>
          </View>
        </View>

        {/* My Widgets section */}
        <View style={styles.sectionHeaderRow}>
          <Text style={styles.sectionTitle}>My Widgets</Text>

          <TouchableOpacity>
            <Text style={styles.viewAllText}>View All</Text>
          </TouchableOpacity>
        </View>

        <View style={styles.gridContainer}>
          {MY_WIDGETS.map((item) => (
            <View key={item.id} style={styles.widgetCard}>
              <View style={styles.widgetCardHeader}>
                <View style={styles.widgetIconBox}>
                  <Ionicons name={item.icon as any} size={20} color="#555" />
                </View>

                <TouchableOpacity>
                  <Ionicons
                    name={item.liked ? "heart" : "heart-outline"}
                    size={20}
                    color={item.liked ? "#d65a42" : "#a1a1a1"}
                  />
                </TouchableOpacity>
              </View>

              <Text style={styles.widgetTitle}>{item.title}</Text>
              <Text style={styles.widgetCategory}>{item.category}</Text>
            </View>
          ))}
        </View>

        {/* Saved collections */}
        <View style={styles.sectionHeaderRow}>
          <Text style={styles.sectionTitle}>Saved Collections</Text>
        </View>

        <View style={styles.collectionsContainer}>
          <TouchableOpacity activeOpacity={0.9} style={styles.collectionCard}>
            <ImageBackground
              source={{
                uri: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=600",
              }}
              style={styles.collectionBackground}
              imageStyle={styles.collectionImageRadius}
            >
              <View style={styles.collectionOverlay}>
                <Text style={styles.collectionTitle}>Minimalist</Text>
                <Text style={styles.collectionSubtitle}>
                  24 ITEMS • CURATED BY YOU
                </Text>
              </View>
            </ImageBackground>
          </TouchableOpacity>

          <TouchableOpacity activeOpacity={0.9} style={styles.collectionCard}>
            <ImageBackground
              source={{
                uri: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=600",
              }}
              style={styles.collectionBackground}
              imageStyle={styles.collectionImageRadius}
            >
              <View style={styles.collectionOverlay}>
                <Text style={styles.collectionTitle}>Productivity</Text>
                <Text style={styles.collectionSubtitle}>
                  18 ITEMS • PRIVATE
                </Text>
              </View>
            </ImageBackground>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  // Screen container
  container: {
    flex: 1,
    backgroundColor: "#fcfbfa",
  },

  // Header
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: 20,
    paddingVertical: 12,
  },

  headerTitle: {
    fontSize: 28,
    fontWeight: "700",
    color: "#000",
  },

  headerIcons: {
    flexDirection: "row",
    alignItems: "center",
  },

  iconButton: {
    marginRight: 12,
    padding: 4,
  },

  smallAvatar: {
    width: 32,
    height: 32,
    borderRadius: 16,
  },

  scrollContent: {
    paddingBottom: 110,
  },

  // Profile section
  avatarSection: {
    alignItems: "center",
    marginTop: 20,
    marginBottom: 24,
  },

  avatarContainer: {
    position: "relative",
    padding: 6,
    borderRadius: 70,
    borderWidth: 1,
    borderColor: "#e5e3e0",
  },

  mainAvatar: {
    width: 110,
    height: 110,
    borderRadius: 55,
  },

  verifiedBadge: {
    position: "absolute",
    bottom: 4,
    right: 4,
    backgroundColor: "#d65a42",
    width: 26,
    height: 26,
    borderRadius: 13,
    justifyContent: "center",
    alignItems: "center",
    borderWidth: 2,
    borderColor: "#fcfbfa",
  },

  profileName: {
    fontSize: 26,
    fontWeight: "700",
    color: "#1a1a1a",
    marginTop: 12,
  },

  profileHandle: {
    fontSize: 14,
    color: "#8e8e93",
    marginTop: 4,
  },

  // Statistics
  statsContainer: {
    flexDirection: "row",
    justifyContent: "space-around",
    alignItems: "center",
    marginHorizontal: 20,
    paddingVertical: 16,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: "#f0efed",
    marginBottom: 28,
  },

  statBox: {
    alignItems: "center",
    flex: 1,
  },

  statNumber: {
    fontSize: 20,
    fontWeight: "700",
    color: "#1a1a1a",
  },

  statLabel: {
    fontSize: 10,
    color: "#8e8e93",
    fontWeight: "600",
    marginTop: 4,
    letterSpacing: 0.5,
  },

  divider: {
    width: 1,
    height: 30,
    backgroundColor: "#e5e3e0",
  },

  // Section headers
  sectionHeaderRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: 20,
    marginBottom: 16,
  },

  sectionTitle: {
    fontSize: 22,
    fontWeight: "700",
    color: "#1a1a1a",
  },

  viewAllText: {
    fontSize: 14,
    color: "#d65a42",
    fontWeight: "600",
  },

  // Widget grid
  gridContainer: {
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "space-between",
    paddingHorizontal: 20,
    marginBottom: 24,
  },

  widgetCard: {
    width: "48%",
    backgroundColor: "#fff",
    borderRadius: 16,
    padding: 14,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: "#f0efed",
  },

  widgetCardHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 20,
  },

  widgetIconBox: {
    backgroundColor: "#f4f3f0",
    padding: 6,
    borderRadius: 8,
  },

  widgetTitle: {
    fontSize: 14,
    fontWeight: "700",
    color: "#1a1a1a",
  },

  widgetCategory: {
    fontSize: 11,
    color: "#8e8e93",
    marginTop: 4,
  },

  // Collections
  collectionsContainer: {
    paddingHorizontal: 20,
  },

  collectionCard: {
    height: 140,
    borderRadius: 16,
    overflow: "hidden",
    marginBottom: 16,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },

  collectionBackground: {
    width: "100%",
    height: "100%",
    justifyContent: "flex-end",
  },

  collectionImageRadius: {
    borderRadius: 16,
  },

  collectionOverlay: {
    padding: 16,
    backgroundColor: "rgba(0, 0, 0, 0.35)",
    height: "100%",
    justifyContent: "flex-end",
  },

  collectionTitle: {
    color: "#fff",
    fontSize: 20,
    fontWeight: "700",
  },

  collectionSubtitle: {
    color: "rgba(255, 255, 255, 0.8)",
    fontSize: 11,
    fontWeight: "600",
    marginTop: 4,
    letterSpacing: 0.5,
  },
});

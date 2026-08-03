import { Ionicons } from "@expo/vector-icons";
import React from "react";
import {
  Image,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

// Settings menu items
const SETTINGS_OPTIONS = [
  { id: "1", label: "Account", icon: "person-outline" },
  { id: "2", label: "Notifications", icon: "notifications-outline" },
  { id: "3", label: "Appearance", icon: "color-palette-outline" },
  { id: "4", label: "Privacy", icon: "lock-closed-outline" },
  { id: "5", label: "Help & Support", icon: "help-circle-outline" },
];

export default function SettingsScreen() {
  return (
    <SafeAreaView style={styles.container} edges={["top", "left", "right"]}>
      {/* Screen header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Settings</Text>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* User profile section */}
        <View style={styles.profileSection}>
          <View style={styles.avatarContainer}>
            <Image
              source={{
                uri: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150",
              }}
              style={styles.mainAvatar}
            />
          </View>

          <Text style={styles.userName}>Alex Mercer</Text>
          <Text style={styles.userRole}>Premium Collector</Text>
        </View>

        {/* Settings options */}
        <View style={styles.cardContainer}>
          {SETTINGS_OPTIONS.map((item, index) => {
            const isLastItem = index === SETTINGS_OPTIONS.length - 1;

            return (
              <View key={item.id}>
                <TouchableOpacity style={styles.rowItem} activeOpacity={0.7}>
                  <View style={styles.rowLeft}>
                    {/* Option icon */}
                    <View style={styles.iconBox}>
                      <Ionicons
                        name={item.icon as any}
                        size={22}
                        color="#555"
                      />
                    </View>

                    <Text style={styles.rowLabel}>{item.label}</Text>
                  </View>

                  <Ionicons name="chevron-forward" size={18} color="#c7c7cc" />
                </TouchableOpacity>

                {/* Divider between menu items */}
                {!isLastItem && <View style={styles.rowDivider} />}
              </View>
            );
          })}
        </View>

        {/* Log out button */}
        <TouchableOpacity style={styles.logoutButton} activeOpacity={0.6}>
          <Ionicons
            name="log-out-outline"
            size={20}
            color="#555"
            style={styles.logoutIcon}
          />
          <Text style={styles.logoutText}>Log Out</Text>
        </TouchableOpacity>

        {/* App footer */}
        <View style={styles.footer}>
          <Text style={styles.footerBrand}>Widgy</Text>
          <Text style={styles.footerVersion}>VERSION 1.0.0 (2026)</Text>
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
    marginRight: 14,
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
  profileSection: {
    alignItems: "center",
    marginTop: 20,
    marginBottom: 28,
  },

  avatarContainer: {
    width: 110,
    height: 110,
    borderRadius: 55,
    borderWidth: 1,
    borderColor: "#e5e3e0",
    padding: 4,
    justifyContent: "center",
    alignItems: "center",
    position: "relative",
    backgroundColor: "#fff",
  },

  mainAvatar: {
    width: "100%",
    height: "100%",
    borderRadius: 55,
  },

  avatarOverlay: {
    position: "absolute",
    alignItems: "center",
  },

  avatarOverlayText: {
    fontSize: 9,
    fontWeight: "700",
    color: "#333",
    marginTop: 4,
  },

  avatarOverlaySubtext: {
    fontSize: 7,
    color: "#777",
    marginTop: 1,
  },

  userName: {
    fontSize: 24,
    fontWeight: "700",
    color: "#1a1a1a",
    marginTop: 14,
  },

  userRole: {
    fontSize: 13,
    color: "#8e8e93",
    marginTop: 2,
  },

  // Settings card
  cardContainer: {
    backgroundColor: "#fff",
    marginHorizontal: 20,
    borderRadius: 28,
    paddingHorizontal: 16,
    borderWidth: 1,
    borderColor: "#f0efed",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.03,
    shadowRadius: 8,
    elevation: 2,
  },

  rowItem: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingVertical: 14,
  },

  rowLeft: {
    flexDirection: "row",
    alignItems: "center",
  },

  iconBox: {
    backgroundColor: "#f4f3f0",
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: "center",
    alignItems: "center",
    marginRight: 14,
  },

  rowLabel: {
    fontSize: 15,
    fontWeight: "600",
    color: "#1a1a1a",
  },

  rowDivider: {
    height: 1,
    backgroundColor: "#f4f3f0",
    marginLeft: 54,
  },

  // Log out button
  logoutButton: {
    flexDirection: "row",
    justifyContent: "center",
    alignItems: "center",
    marginTop: 32,
    alignSelf: "center",
    paddingVertical: 8,
    paddingHorizontal: 16,
  },

  logoutIcon: {
    marginRight: 8,
  },

  logoutText: {
    fontSize: 15,
    fontWeight: "600",
    color: "#555",
  },

  // Footer
  footer: {
    alignItems: "center",
    marginTop: 24,
    marginBottom: 10,
  },

  footerBrand: {
    fontSize: 22,
    fontWeight: "700",
    color: "#a1a1a1",
    fontFamily: "System",
  },

  footerVersion: {
    fontSize: 10,
    color: "#c4c4c6",
    fontWeight: "600",
    marginTop: 6,
    letterSpacing: 0.8,
  },
});

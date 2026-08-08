import React, { useEffect, useState } from "react";
import {
  ActivityIndicator,
  FlatList,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { SafeAreaView } from "react-native-safe-area-context";
import { getAllThemes, type Theme } from "@/configs/proverbService";

const CATEGORIES = ["Tümü", "Ücretsiz", "Premium"];

export default function MarketScreen() {
  const [themes, setThemes] = useState<Theme[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeCategory, setActiveCategory] = useState("Tümü");
  const [searchQuery, setSearchQuery] = useState("");

  useEffect(() => {
    getAllThemes()
      .then((data) => setThemes(data))
      .catch((err) => console.error("MarketScreen Firebase Hata:", err))
      .finally(() => setLoading(false));
  }, []);

  const filteredThemes = themes
    .filter((t) => {
      if (activeCategory === "Ücretsiz") return !t.is_premium;
      if (activeCategory === "Premium") return t.is_premium;
      return true;
    })
    .filter((t) => t.name.toLowerCase().includes(searchQuery.toLowerCase()));

  return (
    <SafeAreaView style={styles.container} edges={["top", "left", "right"]}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingBottom: 100 }}
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>Tema Mağazası</Text>
          <TouchableOpacity>
            <Ionicons name="filter-outline" size={24} color="#1a1a1a" />
          </TouchableOpacity>
        </View>

        {/* Search */}
        <View style={styles.searchContainer}>
          <Ionicons name="search" size={20} color="#7e7e7e" />
          <TextInput
            placeholder="Tema ara..."
            placeholderTextColor="#7e7e7e"
            style={styles.search}
            value={searchQuery}
            onChangeText={setSearchQuery}
          />
        </View>

        {/* Categories */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.categories}
        >
          {CATEGORIES.map((item) => (
            <TouchableOpacity
              key={item}
              style={[
                styles.category,
                activeCategory === item && styles.activeCategory,
              ]}
              onPress={() => setActiveCategory(item)}
            >
              <Text
                style={[
                  styles.categoryText,
                  activeCategory === item && styles.activeCategoryText,
                ]}
              >
                {item}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* Featured Header */}
        <View style={styles.sectionHeader}>
          <View>
            <Text style={styles.sectionTitle}>Firebase Temaları</Text>
            <Text style={styles.sectionSubtitle}>
              Firestore'dan Canlı Çekilen 5 Estetik Tema
            </Text>
          </View>
        </View>

        {/* Widget list */}
        {loading ? (
          <ActivityIndicator
            color="#d65a42"
            size="large"
            style={{ marginTop: 40 }}
          />
        ) : (
          <FlatList
            data={filteredThemes}
            scrollEnabled={false}
            keyExtractor={(item) => item.id}
            contentContainerStyle={{ paddingHorizontal: 20 }}
            renderItem={({ item }) => (
              <TouchableOpacity style={styles.widgetCard}>
                {/* Visual Theme Preview Box */}
                <View
                  style={[
                    styles.imagePlaceholder,
                    { backgroundColor: item.colors.background },
                  ]}
                >
                  <Text
                    style={[styles.previewText, { color: item.colors.text }]}
                  >
                    {item.name}
                  </Text>
                  <Text
                    style={[
                      styles.previewSubtext,
                      { color: item.colors.accent },
                    ]}
                  >
                    "Ağaç yaşken..."
                  </Text>
                </View>

                <View style={styles.content}>
                  <View
                    style={{
                      flexDirection: "row",
                      justifyContent: "space-between",
                      alignItems: "center",
                    }}
                  >
                    <Text style={styles.widgetTitle}>{item.name}</Text>
                    {item.is_premium ? (
                      <View style={styles.badgePremium}>
                        <Text style={styles.badgePremiumText}>PREMIUM</Text>
                      </View>
                    ) : (
                      <View style={styles.badgeFree}>
                        <Text style={styles.badgeFreeText}>ÜCRETSİZ</Text>
                      </View>
                    )}
                  </View>

                  <Text style={styles.creator}>Font: {item.font_family}</Text>

                  <View style={styles.infoRow}>
                    <Text style={styles.info}>Düzen: {item.layout_style}</Text>
                  </View>

                  <TouchableOpacity
                    style={[
                      styles.installButton,
                      item.is_premium && { backgroundColor: "#1a1a1a" },
                    ]}
                  >
                    <Text style={styles.installText}>
                      {item.is_premium
                        ? "Kilidi Aç (49.99 TL)"
                        : "Temayı Kullan"}
                    </Text>
                  </TouchableOpacity>
                </View>
              </TouchableOpacity>
            )}
          />
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fcfbfa",
  },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    paddingHorizontal: 20,
    paddingTop: 10,
  },
  title: {
    fontSize: 28,
    fontWeight: "700",
    color: "#1a1a1a",
  },
  searchContainer: {
    margin: 20,
    height: 48,
    borderRadius: 16,
    backgroundColor: "#ffffff",
    borderWidth: 1,
    borderColor: "#f0efed",
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
  },
  search: {
    flex: 1,
    marginLeft: 10,
    fontSize: 15,
    color: "#1a1a1a",
  },
  categories: {
    paddingHorizontal: 20,
    gap: 10,
  },
  category: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: "#ffffff",
    borderWidth: 1,
    borderColor: "#f0efed",
  },
  activeCategory: {
    backgroundColor: "#d65a42",
    borderColor: "#d65a42",
  },
  categoryText: {
    color: "#7e7e7e",
    fontSize: 13,
    fontWeight: "600",
  },
  activeCategoryText: {
    color: "#ffffff",
  },
  sectionHeader: {
    paddingHorizontal: 20,
    marginTop: 30,
    marginBottom: 15,
  },
  sectionTitle: {
    fontSize: 22,
    fontWeight: "700",
    color: "#1a1a1a",
  },
  sectionSubtitle: {
    marginTop: 3,
    color: "#7e7e7e",
    fontSize: 13,
  },
  widgetCard: {
    backgroundColor: "#ffffff",
    borderRadius: 20,
    padding: 12,
    flexDirection: "row",
    marginBottom: 16,
    borderWidth: 1,
    borderColor: "#f0efed",
  },
  imagePlaceholder: {
    width: 110,
    height: 110,
    borderRadius: 16,
    justifyContent: "center",
    alignItems: "center",
    padding: 8,
    borderWidth: 1,
    borderColor: "#e0e0e0",
  },
  previewText: {
    fontSize: 12,
    fontWeight: "700",
    textAlign: "center",
  },
  previewSubtext: {
    fontSize: 10,
    marginTop: 4,
    fontStyle: "italic",
  },
  content: {
    flex: 1,
    marginLeft: 14,
  },
  widgetTitle: {
    fontSize: 15,
    fontWeight: "700",
    color: "#1a1a1a",
  },
  badgePremium: {
    backgroundColor: "#FEF3C7",
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 8,
  },
  badgePremiumText: {
    color: "#D97706",
    fontSize: 9,
    fontWeight: "700",
  },
  badgeFree: {
    backgroundColor: "#D1FAE5",
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 8,
  },
  badgeFreeText: {
    color: "#059669",
    fontSize: 9,
    fontWeight: "700",
  },
  creator: {
    marginTop: 3,
    color: "#7e7e7e",
    fontSize: 13,
  },
  infoRow: {
    flexDirection: "row",
    gap: 15,
    marginTop: 6,
  },
  info: {
    color: "#7e7e7e",
    fontSize: 12,
  },
  installButton: {
    marginTop: 10,
    backgroundColor: "#d65a42",
    paddingVertical: 8,
    borderRadius: 12,
    alignItems: "center",
  },
  installText: {
    color: "#ffffff",
    fontWeight: "700",
    fontSize: 13,
  },
});

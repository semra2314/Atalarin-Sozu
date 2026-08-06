import React from "react";
import {
  FlatList,
  Image,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";

import { Ionicons } from "@expo/vector-icons";
import { SafeAreaView } from "react-native-safe-area-context";

const WIDGETS = [
  {
    id: "1",
    title: "Neo Classical Mono",
    creator: "Studio Arvo",
    category: "Minimal",
    downloads: "12.4k",
    rating: "4.9",
    image:
      "https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?q=80&w=400",
  },
  {
    id: "2",
    title: "Turkish Proverbs",
    creator: "Widgy Studio",
    category: "Quotes",
    downloads: "8.2k",
    rating: "4.8",
    image:
      "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?q=80&w=400",
  },
  {
    id: "3",
    title: "Glass Weather",
    creator: "Liam V.",
    category: "Weather",
    downloads: "6.5k",
    rating: "4.7",
    image:
      "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=400",
  },
];

const CATEGORIES = [
  "All",
  "Minimal",
  "Quotes",
  "Clock",
  "Weather",
  "Productivity",
];

export default function MarketScreen() {
  return (
    <SafeAreaView style={styles.container} edges={["top", "left", "right"]}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{
          paddingBottom: 100,
        }}
      >
        {/* Header */}

        <View style={styles.header}>
          <Text style={styles.title}>Market</Text>

          <TouchableOpacity>
            <Ionicons name="filter-outline" size={24} color="#1a1a1a" />
          </TouchableOpacity>
        </View>

        {/* Search */}

        <View style={styles.searchContainer}>
          <Ionicons name="search" size={20} color="#7e7e7e" />

          <TextInput
            placeholder="Search widgets..."
            placeholderTextColor="#7e7e7e"
            style={styles.search}
          />
        </View>

        {/* Categories */}

        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.categories}
        >
          {CATEGORIES.map((item, index) => (
            <TouchableOpacity
              key={item}
              style={[styles.category, index === 0 && styles.activeCategory]}
            >
              <Text
                style={[
                  styles.categoryText,

                  index === 0 && styles.activeCategoryText,
                ]}
              >
                {item}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>

        {/* Featured */}

        <View style={styles.sectionHeader}>
          <View>
            <Text style={styles.sectionTitle}>Popular Widgets</Text>

            <Text style={styles.sectionSubtitle}>Loved by the community</Text>
          </View>
        </View>

        {/* Widget list */}

        <FlatList
          data={WIDGETS}
          scrollEnabled={false}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{
            paddingHorizontal: 20,
          }}
          renderItem={({ item }) => (
            <TouchableOpacity style={styles.widgetCard}>
              <Image
                source={{
                  uri: item.image,
                }}
                style={styles.image}
              />

              <View style={styles.content}>
                <Text style={styles.widgetTitle}>{item.title}</Text>

                <Text style={styles.creator}>{item.creator}</Text>

                <View style={styles.infoRow}>
                  <Text style={styles.info}>★ {item.rating}</Text>

                  <Text style={styles.info}>↓ {item.downloads}</Text>
                </View>

                <TouchableOpacity style={styles.installButton}>
                  <Text style={styles.installText}>Install</Text>
                </TouchableOpacity>
              </View>
            </TouchableOpacity>
          )}
        />
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

  image: {
    width: 110,
    height: 110,

    borderRadius: 16,
  },

  content: {
    flex: 1,
    marginLeft: 14,
  },

  widgetTitle: {
    fontSize: 16,
    fontWeight: "700",
    color: "#1a1a1a",
  },

  creator: {
    marginTop: 3,
    color: "#7e7e7e",
    fontSize: 13,
  },

  infoRow: {
    flexDirection: "row",
    gap: 15,
    marginTop: 8,
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

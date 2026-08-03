import { Ionicons } from "@expo/vector-icons";
import React from "react";
import {
  FlatList,
  Image,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import HeroCard from "../../components/HeroCard";

// Sample data for the "New Releases" section
const NEW_RELEASES = [
  {
    id: "1",
    title: "Neo-Classical Mono",
    author: "Studio Arvo",
    rating: "4.9",
    image:
      "https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?q=80&w=400",
  },
  {
    id: "2",
    title: "Pulse",
    author: "Liam V.",
    rating: "4.7",
    image:
      "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?q=80&w=400",
  },
];

export default function DiscoverScreen() {
  return (
    <SafeAreaView style={styles.container} edges={["top", "left", "right"]}>
      {/* Screen header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Discover</Text>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* Featured widget */}
        <HeroCard />

        {/* New Releases section */}
        <View style={styles.sectionHeaderRow}>
          <View>
            <Text style={styles.sectionTitle}>New Releases</Text>
            <Text style={styles.sectionSubtitle}>
              Freshly curated functional art.
            </Text>
          </View>

          <TouchableOpacity>
            <Text style={styles.viewAllText}>View all</Text>
          </TouchableOpacity>
        </View>

        {/* Horizontal list */}
        <FlatList
          horizontal
          data={NEW_RELEASES}
          keyExtractor={(item) => item.id}
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.horizontalListPadding}
          renderItem={({ item }) => (
            <View style={styles.horizontalCard}>
              <View style={styles.imageContainer}>
                <Image source={{ uri: item.image }} style={styles.cardImage} />

                {/* Rating badge */}
                <View style={styles.ratingBadge}>
                  <Text style={styles.ratingText}>★ {item.rating}</Text>
                </View>
              </View>

              <Text style={styles.cardTitle}>{item.title}</Text>
              <Text style={styles.cardAuthor}>{item.author}</Text>
            </View>
          )}
        />

        {/* Editor's Choice section */}
        <View style={styles.sectionHeaderRow}>
          <View>
            <Text style={styles.sectionTitle}>Editor's Choice</Text>
          </View>
        </View>

        {/* Featured collections */}
        <View style={styles.verticalListContainer}>
          <TouchableOpacity style={styles.rowItem}>
            <Image
              source={{
                uri: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=150",
              }}
              style={styles.rowImage}
            />

            <View style={styles.rowContent}>
              <Text style={styles.rowTitle}>The Scholarly Suite</Text>
              <Text style={styles.rowSubtitle} numberOfLines={1}>
                A complete collection of...
              </Text>
            </View>

            <Ionicons name="chevron-forward" size={18} color="#a1a1a1" />
          </TouchableOpacity>

          <TouchableOpacity style={styles.rowItem}>
            <Image
              source={{
                uri: "https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?q=80&w=150",
              }}
              style={styles.rowImage}
            />

            <View style={styles.rowContent}>
              <Text style={styles.rowTitle}>Abstract Vibe</Text>
              <Text style={styles.rowSubtitle} numberOfLines={1}>
                Dynamic geometric widgets...
              </Text>
            </View>

            <Ionicons name="chevron-forward" size={18} color="#a1a1a1" />
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
    paddingVertical: 10,
    backgroundColor: "#fcfbfa",
  },

  avatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
  },

  headerTitle: {
    fontSize: 24,
    fontWeight: "700",
    fontFamily: "System",
  },

  iconButton: {
    padding: 4,
  },

  scrollContent: {
    paddingBottom: 100,
  },

  // Section headers
  sectionHeaderRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "flex-end",
    paddingHorizontal: 20,
    marginTop: 24,
    marginBottom: 12,
  },

  sectionTitle: {
    fontSize: 22,
    fontWeight: "700",
    color: "#1a1a1a",
  },

  sectionSubtitle: {
    fontSize: 13,
    color: "#7e7e7e",
    marginTop: 2,
  },

  viewAllText: {
    fontSize: 13,
    color: "#d65a42",
    fontWeight: "600",
  },

  // Horizontal list
  horizontalListPadding: {
    paddingLeft: 20,
    paddingRight: 10,
  },

  horizontalCard: {
    width: 200,
    marginRight: 16,
  },

  imageContainer: {
    position: "relative",
    borderRadius: 20,
    overflow: "hidden",
    marginBottom: 8,
  },

  cardImage: {
    width: "100%",
    height: 200,
  },

  ratingBadge: {
    position: "absolute",
    top: 10,
    right: 10,
    backgroundColor: "rgba(255, 255, 255, 0.85)",
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 12,
  },

  ratingText: {
    fontSize: 11,
    fontWeight: "700",
    color: "#1a1a1a",
  },

  cardTitle: {
    fontSize: 15,
    fontWeight: "600",
    color: "#1a1a1a",
  },

  cardAuthor: {
    fontSize: 13,
    color: "#7e7e7e",
  },

  // Vertical list
  verticalListContainer: {
    paddingHorizontal: 20,
  },

  rowItem: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#fff",
    padding: 12,
    borderRadius: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: "#f0efed",
  },

  rowImage: {
    width: 50,
    height: 50,
    borderRadius: 12,
  },

  rowContent: {
    flex: 1,
    marginLeft: 12,
    marginRight: 8,
  },

  rowTitle: {
    fontSize: 15,
    fontWeight: "600",
    color: "#1a1a1a",
  },

  rowSubtitle: {
    fontSize: 13,
    color: "#7e7e7e",
    marginTop: 2,
  },
});

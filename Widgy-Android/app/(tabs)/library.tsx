import React from "react";
import {
  FlatList,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import { SafeAreaView } from "react-native-safe-area-context";

const colors = {
  background: "#fcfbfa",
  card: "#ffffff",
  text: "#1a1a1a",
  secondary: "#7e7e7e",
  accent: "#d65a42",
  border: "#f0efed",
};

const MY_WIDGETS = [
  {
    id: "1",
    title: "Turkish Proverbs",
    category: "Atasözü",
    template: "Proverb",
    preview: "Ağaç yaşken eğilir.",
  },
  {
    id: "2",
    title: "Minimal Clock",
    category: "Clock",
    template: "Clock",
    preview: "12:45",
  },
];

export default function LibraryScreen() {
  return (
    <SafeAreaView style={styles.container} edges={["top", "left", "right"]}>
      <View style={styles.header}>
        <Text style={styles.title}>Library</Text>

        <Text style={styles.subtitle}>Your widget collection</Text>
      </View>

      <FlatList
        data={MY_WIDGETS}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => (
          <TouchableOpacity style={styles.card}>
            {/* Widget preview */}
            <View style={styles.preview}>
              <Text style={styles.previewText}>{item.preview}</Text>
            </View>

            <Text style={styles.cardTitle}>{item.title}</Text>

            <Text style={styles.cardCategory}>{item.category}</Text>
          </TouchableOpacity>
        )}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },

  header: {
    paddingHorizontal: 20,
    paddingTop: 10,
  },

  title: {
    fontSize: 28,
    fontWeight: "700",
    color: colors.text,
  },

  subtitle: {
    marginTop: 4,
    fontSize: 14,
    color: colors.secondary,
  },

  list: {
    padding: 20,
    paddingBottom: 100,
  },

  card: {
    backgroundColor: colors.card,

    borderRadius: 20,

    padding: 16,

    marginBottom: 16,

    borderWidth: 1,

    borderColor: colors.border,
  },

  preview: {
    height: 150,

    borderRadius: 16,

    backgroundColor: "#f7f5f2",

    justifyContent: "center",

    alignItems: "center",
  },

  previewText: {
    fontSize: 22,

    fontWeight: "600",

    color: colors.text,
  },

  cardTitle: {
    marginTop: 12,

    fontSize: 16,

    fontWeight: "600",

    color: colors.text,
  },

  cardCategory: {
    marginTop: 4,

    fontSize: 13,

    color: colors.secondary,
  },
});

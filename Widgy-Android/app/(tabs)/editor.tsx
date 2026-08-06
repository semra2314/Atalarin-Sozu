import React, { useState } from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import { SafeAreaView } from "react-native-safe-area-context";

import WidgetCanvas from "@/components/WidgetCanvas";
import { defaultProverbConfig } from "@/configs/proverbConfig";
import type { WidgetConfig } from "@/types/WidgetConfig";

export default function EditorScreen() {
  const [config, setConfig] = useState<WidgetConfig>(defaultProverbConfig);

  function updateStyle(
    key: keyof WidgetConfig["style"],
    value: string | number,
  ) {
    setConfig({
      ...config,

      style: {
        ...config.style,

        [key]: value,
      },
    });
  }

  function updateText(text: string) {
    setConfig({
      ...config,

      data: {
        ...config.data,
        text,
      },
    });
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView>
        <Text style={styles.title}>Edit Widget</Text>

        {/* TEMPLATE SELECTOR */}

        <Text style={styles.sectionTitle}>Template</Text>

        <View style={styles.templates}>
          <TouchableOpacity style={styles.templateCard}>
            <Text>📖 Proverb</Text>
          </TouchableOpacity>

          <TouchableOpacity style={styles.templateCard}>
            <Text>🕒 Clock</Text>
          </TouchableOpacity>
        </View>

        {/* PREVIEW */}

        <Text style={styles.sectionTitle}>Preview</Text>

        <View style={styles.previewContainer}>
          <WidgetCanvas config={config} />
        </View>

        {/* CUSTOMIZATION */}

        <Text style={styles.sectionTitle}>Customize</Text>

        <TouchableOpacity
          style={styles.option}
          onPress={() => updateStyle("backgroundColor", "#202020")}
        >
          <Text>Dark Background</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.option}
          onPress={() => updateStyle("fontSize", config.style.fontSize + 2)}
        >
          <Text>Increase Font Size</Text>
        </TouchableOpacity>

        <TouchableOpacity style={styles.saveButton}>
          <Text style={styles.saveText}>Save Widget</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#fcfbfa",
  },

  title: {
    fontSize: 28,
    fontWeight: "700",
    margin: 20,
    color: "#1a1a1a",
  },

  sectionTitle: {
    fontSize: 20,
    fontWeight: "700",
    marginHorizontal: 20,
    marginTop: 24,
    marginBottom: 12,
    color: "#1a1a1a",
  },

  templates: {
    flexDirection: "row",
    paddingHorizontal: 20,
    gap: 12,
  },

  templateCard: {
    backgroundColor: "#fff",
    padding: 18,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#f0efed",
  },

  previewContainer: {
    alignItems: "center",
    marginTop: 10,
  },

  option: {
    marginHorizontal: 20,
    padding: 16,
    backgroundColor: "#fff",
    borderRadius: 16,
    marginBottom: 10,
  },

  saveButton: {
    margin: 20,
    padding: 18,
    borderRadius: 16,
    backgroundColor: "#d65a42",
    alignItems: "center",
  },

  saveText: {
    color: "#fff",
    fontWeight: "700",
  },
});

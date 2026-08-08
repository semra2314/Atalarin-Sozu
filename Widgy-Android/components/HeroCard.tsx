import React, { useEffect, useState } from "react";
import {
  ActivityIndicator,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import {
  getDailyProverbId,
  getProverbById,
  type Proverb,
} from "@/configs/proverbService";

export default function HeroCard() {
  const [currentId, setCurrentId] = useState<number>(getDailyProverbId());
  const [proverb, setProverb] = useState<Proverb | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    getProverbById(currentId)
      .then((data) => setProverb(data))
      .catch((err) => console.error("HeroCard Firebase hata:", err))
      .finally(() => setLoading(false));
  }, [currentId]);

  const handleNextDay = () => {
    // 400 atasözü arasında döngüsel ilerle (1 .. 400)
    setCurrentId((prev) => (prev % 400) + 1);
  };

  const handlePrevDay = () => {
    // 400 atasözü arasında geriye git
    setCurrentId((prev) => (prev === 1 ? 400 : prev - 1));
  };

  return (
    <View style={styles.cardContainer}>
      <View style={styles.gradientBackground}>
        <View style={styles.overlay}>
          {/* Top Header Row */}
          <View style={styles.badgeRow}>
            <View style={styles.badge}>
              <Text style={styles.badgeText}>GÜNÜN ATASÖZÜ</Text>
            </View>
            <Text style={styles.idCounter}>
              ID: #{currentId} / 400
            </Text>
          </View>

          {/* Content */}
          {loading ? (
            <ActivityIndicator
              color="#fff"
              size="large"
              style={{ marginVertical: 24 }}
            />
          ) : (
            <>
              <Text style={styles.title}>
                {proverb?.title ?? "Ağaç yaşken eğilir."}
              </Text>
              <Text style={styles.type}>
                {proverb?.type ?? "Atasözü"}
              </Text>
              <Text style={styles.meaning}>
                {proverb?.meaning ?? ""}
              </Text>
              {proverb?.example_sentence ? (
                <Text style={styles.example}>
                  "{proverb.example_sentence}"
                </Text>
              ) : null}
            </>
          )}

          {/* Navigation Controls Row */}
          <View style={styles.controlsRow}>
            <TouchableOpacity
              style={styles.navButton}
              onPress={handlePrevDay}
              activeOpacity={0.8}
            >
              <Ionicons name="chevron-back" size={16} color="#fff" />
              <Text style={styles.navButtonText}>Önceki Gün</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.navButton, styles.nextButton]}
              onPress={handleNextDay}
              activeOpacity={0.8}
            >
              <Text style={[styles.navButtonText, styles.nextButtonText]}>
                Sonraki Gün
              </Text>
              <Ionicons name="chevron-forward" size={16} color="#d65a42" />
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  cardContainer: {
    marginHorizontal: 20,
    marginVertical: 12,
    borderRadius: 24,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.12,
    shadowRadius: 16,
    elevation: 6,
    overflow: "hidden",
  },

  gradientBackground: {
    width: "100%",
    minHeight: 220,
    backgroundColor: "#d65a42",
  },

  overlay: {
    padding: 22,
    backgroundColor: "rgba(0, 0, 0, 0.15)",
  },

  badgeRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 12,
  },

  badge: {
    backgroundColor: "rgba(255,255,255,0.2)",
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.3)",
  },

  badgeText: {
    color: "#fff",
    fontSize: 9,
    fontWeight: "700",
    letterSpacing: 1,
  },

  idCounter: {
    color: "rgba(255,255,255,0.75)",
    fontSize: 11,
    fontWeight: "600",
  },

  title: {
    color: "#fff",
    fontSize: 22,
    fontWeight: "700",
    lineHeight: 30,
    marginBottom: 4,
  },

  type: {
    color: "rgba(255,255,255,0.7)",
    fontSize: 11,
    fontWeight: "600",
    marginBottom: 8,
    textTransform: "uppercase",
    letterSpacing: 0.5,
  },

  meaning: {
    color: "rgba(255,255,255,0.9)",
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 6,
  },

  example: {
    color: "rgba(255,255,255,0.75)",
    fontSize: 12,
    fontStyle: "italic",
    lineHeight: 18,
    marginBottom: 14,
  },

  controlsRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.2)",
  },

  navButton: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.2)",
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 16,
    gap: 4,
  },

  nextButton: {
    backgroundColor: "#ffffff",
  },

  navButtonText: {
    color: "#ffffff",
    fontSize: 12,
    fontWeight: "700",
  },

  nextButtonText: {
    color: "#d65a42",
  },
});

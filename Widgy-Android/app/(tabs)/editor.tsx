import { HelloWidget } from "@/widget/HelloWidget";
import { StyleSheet, View } from "react-native";
import { WidgetPreview } from "react-native-android-widget";

export default function Editor() {
  return (
    <View style={styles.container}>
      <WidgetPreview
        renderWidget={() => <HelloWidget />}
        width={320}
        height={200}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
  },
});

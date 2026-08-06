import type { WidgetConfig } from "@/types/WidgetConfig";
import { Text, View } from "react-native";

type Props = {
  config: WidgetConfig;
};

export default function WidgetCanvas({ config }: Props) {
  return (
    <View
      style={{
        width: 320,
        height: 160,

        backgroundColor: config.style.backgroundColor,

        borderRadius: config.style.borderRadius,

        padding: 20,

        justifyContent: "center",

        shadowColor: "#000",
        shadowOpacity: 0.08,
        shadowRadius: 10,
      }}
    >
      <Text
        style={{
          fontSize: config.style.fontSize,

          color: config.style.textColor,

          fontWeight: "600",
        }}
      >
        {config.data.text}
      </Text>

      {config.data.author && (
        <Text
          style={{
            marginTop: 8,
            color: "#777",
          }}
        >
          {config.data.author}
        </Text>
      )}
    </View>
  );
}

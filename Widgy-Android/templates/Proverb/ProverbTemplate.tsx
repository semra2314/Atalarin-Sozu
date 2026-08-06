import type { WidgetConfig } from "@/types/WidgetConfig";
import { Text, View } from "react-native";

type Props = {
  config: WidgetConfig;
};

export function ProverbTemplate({ config }: Props) {
  return (
    <View
      style={{
        backgroundColor: config.style.backgroundColor,
        borderRadius: config.style.borderRadius,
      }}
    >
      <Text
        style={{
          color: config.style.textColor,
          fontSize: config.style.fontSize,
        }}
      >
        {config.data.text}
      </Text>

      {config.data.author && <Text>{config.data.author}</Text>}
    </View>
  );
}

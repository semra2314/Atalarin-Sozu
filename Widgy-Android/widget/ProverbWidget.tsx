"use no memo";

import { Proverb } from "@/types/WidgetConfig";
import { FlexWidget, TextWidget } from "react-native-android-widget";

export type ProverbWidgetProps = {
  proverb: Proverb;
};

export function ProverbWidget({ proverb }: ProverbWidgetProps) {
  return (
    <FlexWidget
      style={{
        width: "match_parent",
        height: "match_parent",

        backgroundColor: "#FFFFFF",

        padding: 18,

        borderRadius: 20,
      }}
    >
      <TextWidget
        text="📖 Günün Atasözü"
        style={{
          fontSize: 14,
          color: "#777777",
        }}
      />

      <TextWidget
        text={proverb.proverb}
        style={{
          fontSize: 22,
          color: "#111111",
        }}
      />

      <TextWidget
        text={proverb.meaning}
        style={{
          fontSize: 15,
          color: "#666666",
        }}
      />
    </FlexWidget>
  );
}

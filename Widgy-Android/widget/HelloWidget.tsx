"use no memo";
import { FlexWidget, TextWidget } from "react-native-android-widget";

export type Props = {
  phrase: string;
};

export function HelloWidget({ phrase }: Props) {
  return (
    <FlexWidget
      style={{
        height: "match_parent",
        width: "match_parent",
        justifyContent: "center",
        alignItems: "center",
        backgroundColor: "#ffffff",
        borderRadius: 16,
      }}
      accessibilityLabel="Hello world widget"
    >
      <TextWidget
        text={phrase}
        style={{
          fontSize: 32,
          fontFamily: "Inter",
          color: "#000000",
        }}
      />
    </FlexWidget>
  );
}

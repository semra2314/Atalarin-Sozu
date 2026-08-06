import { Proverb } from "@/types/WidgetConfig";
import React from "react";
import type { WidgetTaskHandlerProps } from "react-native-android-widget";
import { HelloWidget } from "./HelloWidget";
import { ProverbWidget } from "./ProverbWidget";

const nameToWidget = {
  // Hello will be the **name** with which we will reference our widget.
  Proverb: ProverbWidget,
  Hello: HelloWidget,
};
const proverb: Proverb = {
  id: 1,
  type: "Atasözü",
  proverb: "Ağaç yaşken eğilir.",
  meaning: "İnsanlar küçük yaşta kolayca eğitilirler.",
  example:
    "Çocuğuna yabancı dili şimdi öğretmelisin, sonuçta ağaç yaşken eğilir.",
};

export async function widgetTaskHandler(props: WidgetTaskHandlerProps) {
  const widgetInfo = props.widgetInfo;
  const Widget =
    nameToWidget[widgetInfo.widgetName as keyof typeof nameToWidget];

  switch (props.widgetAction) {
    case "WIDGET_ADDED":
      props.renderWidget(<Widget proverb={proverb} phrase={"Hello"} />);
      break;

    case "WIDGET_UPDATE":
      // Not needed for now
      break;

    case "WIDGET_RESIZED":
      // Not needed for now
      break;

    case "WIDGET_DELETED":
      // Not needed for now
      break;

    case "WIDGET_CLICK":
      // Not needed for now
      break;

    default:
      break;
  }
}

import type { WidgetConfig } from "@/types/WidgetConfig";

export const defaultProverbConfig: WidgetConfig = {
  id: "proverb-default",

  type: "Proverb",

  data: {
    text: "Ağaç yaşken eğilir.",
    author: "Atasözü",
  },

  style: {
    backgroundColor: "#ffffff",
    textColor: "#1a1a1a",
    accentColor: "#d65a42",

    borderRadius: 20,
    fontSize: 20,
  },
};

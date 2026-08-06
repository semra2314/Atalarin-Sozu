export type WidgetType = "Proverb";
// | "Clock"
// | "Weather"
// | "Calendar"

export interface WidgetConfig {
  id: string;

  type: WidgetType;

  data: {
    text: string;
    author?: string;
  };

  style: {
    backgroundColor: string;
    textColor: string;
    accentColor: string;

    borderRadius: number;
    fontSize: number;
  };
}

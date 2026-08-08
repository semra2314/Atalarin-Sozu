export type WidgetType = "Proverb";

export interface Proverb {
  id?: number;
  type?: string;
  proverb: string;
  meaning: string;
  example?: string;
}

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


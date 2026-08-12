// The widget catalog, shared by the landing showcase and the dashboard demo.
//
// The preview art here is the same artwork the iOS app ships in its asset
// catalog, re-exported at 600×600 WebP for the web. When a widget's art
// changes in Xcode, re-export it to /public/widgets/<slug>.webp so the portal
// and the app never disagree about what a widget looks like.

export type Widget = {
  slug: string;
  name: string;
  category: string;
  /** One line, the way it reads in the app's gallery. */
  blurb: string;
  /** Live in the shipping app, as opposed to a catalog concept. */
  live: boolean;
};

export const WIDGETS: Widget[] = [
  {
    slug: "aurora",
    name: "Aurora",
    category: "Clock",
    blurb: "A clock whose sky follows the hour, from dawn through to night.",
    live: true,
  },
  {
    slug: "focus",
    name: "Focus",
    category: "Productivity",
    blurb: "A live session timer that keeps counting on the lock screen.",
    live: true,
  },
  {
    slug: "soz",
    name: "Söz",
    category: "Culture",
    blurb: "A Turkish proverb or idiom every four hours, with its meaning.",
    live: true,
  },
  {
    slug: "daily",
    name: "Daily",
    category: "Reading",
    blurb: "A passage each morning from the source you choose.",
    live: true,
  },
  {
    slug: "frame",
    name: "Frame",
    category: "Photography",
    blurb: "Your own photograph, framed for the home screen.",
    live: true,
  },
  {
    slug: "hush",
    name: "Hush",
    category: "Wellbeing",
    blurb: "A breathing pace, and nothing else on the card.",
    live: true,
  },
];

export const widgetBySlug = (slug: string): Widget | undefined =>
  WIDGETS.find((w) => w.slug === slug);

export const previewSrc = (slug: string) => `/widgets/${slug}.webp`;

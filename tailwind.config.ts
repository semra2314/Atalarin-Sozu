import type { Config } from "tailwindcss";

// Same tokens as the iOS app's Theme.swift — keep these two files in sync.
const config: Config = {
  content: [
    "./app/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "#FDF8F8", // warm off-white page
        surface: "#FFFFFF", // cards, nav, sheets
        surfaceMuted: "#F1EDEC", // preview placeholders, 2nd level
        ink: "#1D1D1F", // primary text
        subtleText: "#5E5E63", // secondary text
        hairline: "#E5E2E1", // dividers, thin borders
        accent: "#D44A33", // the ONLY vivid color
        accentTint: "rgba(212, 74, 51, 0.12)",
        // Status badges only — never used as a primary UI color.
        statusPending: "#B5822A",
        statusPendingBg: "#FBF0DE",
        statusApproved: "#2A5C39",
        statusApprovedBg: "#E8F3EB",
        statusDraft: "#5E5E63",
        statusDraftBg: "#F1EDEC",
      },
      fontFamily: {
        serif: ["var(--font-serif)", "ui-serif", "Georgia", "serif"],
        sans: ["var(--font-sans)", "ui-sans-serif", "system-ui", "sans-serif"],
      },
      borderRadius: {
        card: "20px",
        hero: "28px",
        sheet: "28px",
      },
      boxShadow: {
        soft: "0 10px 30px rgba(0, 0, 0, 0.04)",
      },
      maxWidth: {
        container: "1200px",
      },
      spacing: {
        section: "80px",
      },
    },
  },
  plugins: [],
};

export default config;

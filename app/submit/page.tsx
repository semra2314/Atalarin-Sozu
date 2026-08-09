"use client";

import { useState } from "react";
import NavBar from "@/components/NavBar";
import Footer from "@/components/Footer";

const CATEGORIES = ["Focus", "Time", "Mood", "Productivity", "Other"];
const SIZES = ["Small", "Medium", "Large"];

function Chip({
  label,
  selected,
  onClick,
}: {
  label: string;
  selected: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-full border px-4 py-2 text-sm font-medium transition-colors ${
        selected
          ? "border-accent bg-accent text-white"
          : "border-hairline text-ink hover:bg-surfaceMuted"
      }`}
    >
      {label}
    </button>
  );
}

export default function SubmitPage() {
  const [category, setCategory] = useState("Focus");
  const [sizes, setSizes] = useState<string[]>(["Small"]);

  const toggleSize = (size: string) => {
    setSizes((prev) =>
      prev.includes(size) ? prev.filter((s) => s !== size) : [...prev, size]
    );
  };

  return (
    <>
      <NavBar />
      <main className="px-5 py-20 md:px-6">
        <div className="mx-auto max-w-[640px] rounded-hero border border-hairline bg-surface p-8 shadow-soft md:p-12">
          <div className="mb-10 text-center">
            <h1 className="font-serif text-3xl font-semibold text-ink">
              Tell Us About Your Widget
            </h1>
            <p className="mt-2 text-subtleText">
              Review usually takes 2-3 business days.
            </p>
          </div>

          {/* Step indicator */}
          <div className="mb-10 flex items-center justify-center gap-2">
            {["Details", "Images", "Agreement"].map((step, i) => (
              <div key={step} className="max-w-[120px] flex-1">
                <div
                  className={`mb-2 h-2 rounded-full ${
                    i === 0 ? "bg-accent" : "bg-hairline"
                  }`}
                />
                <p
                  className={`text-center text-xs font-bold uppercase tracking-wide ${
                    i === 0 ? "text-accent" : "text-subtleText"
                  }`}
                >
                  {step}
                </p>
              </div>
            ))}
          </div>

          <form className="flex flex-col gap-8">
            <div className="flex flex-col gap-2">
              <label htmlFor="widget-name" className="text-sm font-medium text-ink">
                Widget Name
              </label>
              <input
                id="widget-name"
                type="text"
                placeholder="e.g. Zen Clock"
                className="rounded-lg border border-hairline bg-surfaceMuted px-4 py-3 text-ink placeholder:text-subtleText/60 focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent/20"
              />
            </div>

            <div className="flex flex-col gap-2">
              <span className="text-sm font-medium text-ink">Category</span>
              <div className="flex flex-wrap gap-3">
                {CATEGORIES.map((c) => (
                  <Chip
                    key={c}
                    label={c}
                    selected={category === c}
                    onClick={() => setCategory(c)}
                  />
                ))}
              </div>
            </div>

            <div className="flex flex-col gap-2">
              <label htmlFor="description" className="text-sm font-medium text-ink">
                Description
              </label>
              <textarea
                id="description"
                rows={4}
                placeholder="What does your widget do and why is it useful?"
                className="resize-none rounded-lg border border-hairline bg-surfaceMuted px-4 py-3 text-ink placeholder:text-subtleText/60 focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent/20"
              />
            </div>

            <div className="flex flex-col gap-2">
              <span className="text-sm font-medium text-ink">Sizes Supported</span>
              <div className="flex gap-3">
                {SIZES.map((s) => (
                  <Chip
                    key={s}
                    label={s}
                    selected={sizes.includes(s)}
                    onClick={() => toggleSize(s)}
                  />
                ))}
              </div>
            </div>

            <div className="flex flex-col gap-2">
              <span className="text-sm font-medium text-ink">Screenshots</span>
              <div className="flex flex-col items-center gap-3 rounded-card border-2 border-dashed border-hairline bg-surfaceMuted p-8 text-center transition-colors hover:bg-hairline/30">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-surface shadow-soft">
                  <span className="text-accent">↑</span>
                </div>
                <p className="text-sm text-subtleText">
                  <span className="font-medium text-accent">Click to upload</span>{" "}
                  or drag and drop
                  <br />
                  PNG, JPG or GIF (max. 5MB)
                </p>
              </div>
            </div>

            <div className="mt-2 flex items-center justify-between rounded-card border border-hairline/50 bg-surfaceMuted/50 p-4 opacity-60">
              <div className="flex flex-col">
                <span className="flex items-center gap-2 text-sm font-medium text-ink">
                  Monetization <span className="text-xs">🔒</span>
                </span>
                <span className="mt-1 text-xs text-subtleText">
                  You&apos;ll choose this after approval.
                </span>
              </div>
              <div className="relative h-6 w-11 rounded-full bg-hairline">
                <div className="absolute left-1 top-1 h-4 w-4 rounded-full bg-surface" />
              </div>
            </div>

            <button
              type="button"
              className="mt-2 w-full rounded-xl bg-accent py-4 text-sm font-bold text-white shadow-soft transition-colors hover:opacity-90"
            >
              Continue to Agreement →
            </button>
          </form>
        </div>
      </main>
      <Footer />
    </>
  );
}

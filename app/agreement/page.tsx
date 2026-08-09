"use client";

import { useState } from "react";

// Placeholder commission rate — update here once the number is final,
// it's used in both the callout and the Revenue Share section below.
const COMMISSION_RATE = "X%";

const SECTIONS = [
  {
    title: "1. Ownership",
    body: "You retain all right, title, and interest, including all intellectual property rights, in and to the widgets, designs, and content you submit to the Widgy Creator Portal. Widgy does not claim ownership of your creations.",
  },
  {
    title: "2. License",
    body: "By submitting a widget, you grant Widgy a worldwide, non-exclusive, royalty-free (subject to the Revenue Share section) license to host, display, distribute, and promote your widget within the Widgy app and on Widgy promotional channels.",
  },
  {
    title: "3. Revenue Share & Commission",
    body: `For any widget offered for paid purchase, Widgy will collect payments on your behalf. Widgy will retain a ${COMMISSION_RATE} commission on the gross sales price. The remainder will be remitted to your designated account on a regular payout schedule. Free widgets are entirely commission-free.`,
  },
  {
    title: "4. Right to Remove",
    body: "You may remove your widgets from the platform at any time. Upon removal, Widgy will cease distributing the widget to new users. However, users who have already downloaded or purchased the widget will retain access to it.",
  },
  {
    title: "5. Content Guidelines",
    body: "All submitted widgets must comply with Widgy's Community Guidelines. You agree not to submit content that is offensive, illegal, infringes on third-party rights, or contains malicious code. Widgy reserves the right to remove any widget that violates these guidelines without prior notice.",
  },
];

export default function AgreementPage() {
  const [agreed, setAgreed] = useState(false);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center px-5 py-20 md:px-6">
      <div className="flex w-full max-w-[720px] flex-col gap-8">
        <div className="flex flex-col gap-4 text-center">
          <h1 className="font-serif text-5xl font-semibold text-ink">
            Your work stays yours.
          </h1>
          <p className="mx-auto max-w-[600px] text-lg text-subtleText">
            We believe creators should own their creations. This agreement
            outlines how you license your widgets to Widgy, ensuring you retain
            all rights while earning a fair share from paid sales.
          </p>
        </div>

        {/* Commission callout — the one number creators care about most */}
        <div className="flex items-center gap-6 rounded-xl border border-hairline bg-surfaceMuted p-6">
          <span className="shrink-0 rounded-full bg-accent px-4 py-1 text-sm font-bold uppercase text-white">
            {COMMISSION_RATE}
          </span>
          <p className="text-ink">
            Widgy&apos;s commission on paid widget sales. You keep the rest —
            free widgets cost you nothing.
          </p>
        </div>

        {/* Scrollable agreement document */}
        <div className="flex h-[400px] flex-col overflow-hidden rounded-hero border border-hairline bg-surface shadow-soft">
          <div className="sticky top-0 z-10 flex items-center justify-between border-b border-hairline bg-surface p-6">
            <h2 className="font-serif text-xl font-semibold text-ink">
              Creator Agreement
            </h2>
          </div>
          <div className="flex flex-col gap-6 overflow-y-auto p-6">
            {SECTIONS.map((section) => (
              <div key={section.title} className="flex flex-col gap-2">
                <h3 className="font-serif text-xl font-semibold text-ink">
                  {section.title}
                </h3>
                <p className="text-subtleText">{section.body}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Consent + actions */}
        <div className="flex flex-col gap-4 pt-2">
          <label className="flex w-fit cursor-pointer items-center gap-3">
            <input
              type="checkbox"
              checked={agreed}
              onChange={(e) => setAgreed(e.target.checked)}
              className="h-5 w-5 rounded border-hairline text-accent focus:ring-accent"
            />
            <span className="text-sm text-ink">
              I have read and agree to the terms above.
            </span>
          </label>

          <div className="flex items-center justify-between border-t border-hairline pt-4">
            <button
              type="button"
              className="px-4 py-2 text-sm font-medium text-ink transition-colors hover:underline"
            >
              Back
            </button>
            <button
              type="button"
              disabled={!agreed}
              className="rounded-full bg-accent px-6 py-3 text-sm font-bold text-white transition-all hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-50"
            >
              Accept & Submit
            </button>
          </div>
        </div>
      </div>
    </main>
  );
}

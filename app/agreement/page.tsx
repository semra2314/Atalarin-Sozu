"use client";

import Link from "next/link";
import { useRef, useState } from "react";
import NavBar from "@/components/NavBar";
import Footer from "@/components/Footer";
import {
  AGREEMENT_EFFECTIVE,
  AGREEMENT_VERSION,
  APPLE_PERCENT,
  COMMISSION_PERCENT,
  PAYOUT,
  POOL_PERCENT,
  SUBSCRIPTION,
  usd,
  worked,
} from "@/lib/terms";

const EXAMPLE = worked(2.99);

type Clause = { title: string; paragraphs: string[] };

const CLAUSES: Clause[] = [
  {
    title: "1. Who this is between",
    paragraphs: [
      "This Creator Agreement is between Widgy (\"Widgy\", \"we\") and you, the individual or entity submitting a widget through the Widgy Creator Portal (\"you\", \"the Creator\"). It takes effect on the date you accept it and governs every widget you submit from that point on.",
      "You confirm that you are at least 18 years old, or that you have the consent of a parent or guardian who accepts these terms on your behalf.",
    ],
  },
  {
    title: "2. What the words mean",
    paragraphs: [
      "\"Widget\" means a design you submit — its layout, artwork, typography, colours, configuration and any content you supply with it. \"Paid Widget\" means a widget you have chosen to offer for a price. \"Free Widget\" means one you offer at no charge. \"Widgy+\" means Widgy's subscription, which gives subscribers access to Paid Widgets without a separate purchase.",
      "\"Net Proceeds\" means the price a user pays, less the fee charged by the app store that processed the transaction, less any refunds, chargebacks and transaction taxes attributable to that sale.",
    ],
  },
  {
    title: "3. Your work stays yours",
    paragraphs: [
      "You keep all right, title and interest in your widgets, including every intellectual property right in them. Widgy claims no ownership of anything you make. Nothing in this agreement transfers, assigns or exclusively licenses your work to us.",
      "You are free to publish the same design elsewhere, on any other platform, at any time. We ask for no exclusivity.",
    ],
  },
  {
    title: "4. The licence you grant us",
    paragraphs: [
      "You grant Widgy a worldwide, non-exclusive, revocable, royalty-free licence to host, reproduce, display, distribute and make available your widget inside the Widgy app, and to reproduce its preview artwork and name in Widgy's store listing, website and marketing of the app.",
      "This licence exists only so that we can do the thing you submitted the widget for: deliver it to users. It ends when you withdraw the widget, subject to clause 10.",
      "We will not modify your design without asking you first, except for technical adaptation — resizing, format conversion and rendering — needed to display it correctly across device sizes and operating system versions.",
    ],
  },
  {
    title: "5. Review and publication",
    paragraphs: [
      "Every submission is reviewed before it goes live. We review for technical soundness, for the content standards in clause 11, and for whether the widget works as described. We are not judging your taste.",
      "We aim to complete review within seven business days. We may ask for changes, and we may decline a submission. If we decline, we will tell you why in writing.",
      "Publication also depends on Apple's own App Store review of the Widgy app. Where Apple requires a change or removal, we must comply, and we will tell you as soon as we can when this affects your widget.",
    ],
  },
  {
    title: "6. Pricing and commission",
    paragraphs: [
      "You choose whether your widget is free or paid, and you set its price from the price points Widgy makes available. You may change the price or move between free and paid at any time; changes apply to future sales only.",
      `Free Widgets carry no commission whatsoever. On a Paid Widget, Widgy retains ${COMMISSION_PERCENT}% of Net Proceeds and the remaining ${100 - COMMISSION_PERCENT}% is yours.`,
      `The commission is calculated on Net Proceeds rather than on the list price. This matters: it means Apple's fee — currently ${APPLE_PERCENT}% under the App Store Small Business Program — is borne proportionally by both of us rather than landing entirely on you.`,
      `Worked example on a ${usd(EXAMPLE.list)} widget: Apple takes ${usd(EXAMPLE.apple)}, leaving Net Proceeds of ${usd(EXAMPLE.net)}. Widgy retains ${usd(EXAMPLE.widgy)} and you receive ${usd(EXAMPLE.creator)} — ${EXAMPLE.creatorSharePercent}% of what the user paid.`,
      "If Apple's fee changes, Net Proceeds change with it and the commission percentage stays the same. We will not raise the commission rate without giving you notice under clause 15.",
    ],
  },
  {
    title: "7. Widgy+ and the creator pool",
    paragraphs: [
      `Widgy+ is a subscription (currently ${usd(SUBSCRIPTION.monthlyUSD)} monthly or ${usd(SUBSCRIPTION.yearlyUSD)} yearly) that lets a subscriber install Paid Widgets without buying them individually. When a subscriber installs your Paid Widget, you are not paid a per-sale commission for that install — you are paid from the creator pool instead.`,
      `Each month, Widgy sets aside ${POOL_PERCENT}% of net Widgy+ subscription revenue as the creator pool. Net subscription revenue means subscription receipts less app store fees, refunds and transaction taxes.`,
      "The pool is divided between creators in proportion to verified active installs of their Paid Widgets by subscribers during that month. An install counts as active if the widget was present on a user's home or lock screen and rendered at least once in the month.",
      `Your dashboard shows your install counts, the size of the pool and your share of it for every month, before the payout is made. If we ever change how the pool is divided, or the ${POOL_PERCENT}% figure, clause 15 applies.`,
      "Free Widgets do not draw from the pool. Users can install them whether or not they subscribe.",
    ],
  },
  {
    title: "8. Getting paid",
    paragraphs: [
      `We account monthly. Amounts earned in a calendar month are paid within ${PAYOUT.netDays} days of that month's end, to the payout details you provide.`,
      `Balances under ${usd(PAYOUT.thresholdUSD)} roll forward and are paid once the total passes that figure. You can request a payout of a smaller balance when you close your account.`,
      "You are responsible for your own taxes. You are an independent creator, not an employee, agent or partner of Widgy, and nothing here creates an employment or partnership relationship. Where law requires us to withhold tax or collect tax documentation, we will do so and tell you.",
      "Payment processing fees on the payout itself — bank transfer charges and currency conversion — are deducted from the amount transferred where the payment provider imposes them.",
    ],
  },
  {
    title: "9. Refunds and chargebacks",
    paragraphs: [
      "App store refunds are granted by Apple, not by Widgy, and we cannot overturn them. Where a sale is refunded or charged back, the corresponding amount is deducted from your next statement.",
      "If a widget attracts an unusual volume of refunds we will contact you before taking any action, and we will show you the numbers we are relying on.",
    ],
  },
  {
    title: "10. Withdrawing your widget",
    paragraphs: [
      "You may withdraw any widget at any time, from your dashboard, without giving a reason. On withdrawal we stop distributing it to new users within seven days.",
      "Users who already bought or installed the widget keep it. We think anything else would be unfair to them, and it is the reason the licence in clause 4 survives withdrawal for those specific copies only.",
      "Withdrawal does not affect amounts already earned, which are paid on the normal schedule.",
    ],
  },
  {
    title: "11. What you promise about your work",
    paragraphs: [
      "You confirm that the widget is yours to submit: that you created it or hold the rights to it, and that distributing it through Widgy infringes nobody's copyright, trademark, design right, privacy or publicity right.",
      "This includes the things people most often forget — fonts, photographs, icons and illustrations. If you used a licensed asset, your licence must permit redistribution inside a commercial app.",
      "Your widget must not contain malicious, deceptive or tracking code; must not collect personal data beyond what it needs to function, and never without disclosure; and must not contain content that is unlawful, hateful, harassing, sexually explicit, or that promotes self-harm or violence.",
      "We may remove a widget that breaches this clause. Where a breach is serious or legally urgent, we may remove it first and tell you immediately afterwards. Otherwise we tell you first and give you a chance to fix it.",
    ],
  },
  {
    title: "12. Data and privacy",
    paragraphs: [
      "Widgy processes install and rendering counts to calculate the creator pool. We share these with you in aggregate. We do not give you the identity of individual users, and you must not attempt to identify them.",
      "If your widget fetches data from an external service, you must disclose this in the submission and it must be covered by the widget's description.",
    ],
  },
  {
    title: "13. Term and termination",
    paragraphs: [
      "This agreement runs until either of us ends it. You may end it at any time by withdrawing your widgets and closing your creator account. We may end it on 30 days' written notice, or immediately if you breach clause 11 in a way that exposes Widgy or its users to legal or security risk.",
      "Clauses 3, 8, 9, 10, 14 and 16 survive termination.",
    ],
  },
  {
    title: "14. Liability",
    paragraphs: [
      "Widgy provides the portal and the app as they are. We do not promise a particular level of sales, installs, visibility or income, and nothing on the site is a forecast you should rely on.",
      "Neither of us is liable to the other for indirect or consequential loss, or for loss of profit, revenue or data. Widgy's total liability to you in any twelve-month period is limited to the amounts payable to you in that period.",
      "Nothing in this clause limits liability that cannot lawfully be limited, including for fraud, or for death or personal injury caused by negligence.",
    ],
  },
  {
    title: "15. Changes to this agreement",
    paragraphs: [
      "We may update these terms. If a change affects your commercial position — the commission rate, the pool percentage, how the pool is divided, or the payout schedule — we will give you at least 30 days' notice by email and in the dashboard before it takes effect.",
      "Sales made before the change are settled on the old terms. If you do not accept a change, you may withdraw your widgets and close your account before it takes effect, and you will still be paid everything already earned.",
      "The version and date of the terms you accepted are recorded on your account, and every past version stays available to you.",
    ],
  },
  {
    title: "16. Law and disputes",
    paragraphs: [
      "This agreement is governed by the laws of the Republic of Türkiye, and the courts of Istanbul have jurisdiction, without affecting any mandatory consumer protection you have under the law of your own country of residence.",
      "Before starting proceedings, both of us agree to raise the issue in writing and to spend 30 days genuinely trying to resolve it.",
      "If any clause is found unenforceable, the rest stays in force.",
    ],
  },
];

export default function AgreementPage() {
  const [readToEnd, setReadToEnd] = useState(false);
  const [agreed, setAgreed] = useState(false);
  const [signature, setSignature] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const scroller = useRef<HTMLDivElement>(null);

  // Only meaningful consent counts: the button stays locked until the document
  // has actually been scrolled through and a name has been typed.
  const handleScroll = () => {
    const el = scroller.current;
    if (!el) return;
    if (el.scrollTop + el.clientHeight >= el.scrollHeight - 24) setReadToEnd(true);
  };

  const canAccept = readToEnd && agreed && signature.trim().length > 2;
  const today = new Date().toLocaleDateString("en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });

  return (
    <>
      <NavBar />
      <main className="mx-auto flex max-w-[820px] flex-col gap-8 px-5 pb-24 pt-32 md:px-6">
        <header className="flex flex-col gap-4 text-center">
          <h1 className="font-serif text-5xl font-semibold text-ink">
            Your work stays yours.
          </h1>
          <p className="mx-auto max-w-[620px] text-lg text-subtleText">
            This is the whole agreement, in plain language. You keep ownership
            of everything you make, you set your own price, and you can take
            your widget back whenever you like.
          </p>
          <p className="text-sm text-subtleText">
            Version {AGREEMENT_VERSION} · Effective {AGREEMENT_EFFECTIVE}
          </p>
        </header>

        {/* The three numbers a creator actually wants before reading anything */}
        <section className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          {[
            {
              value: `${100 - COMMISSION_PERCENT}%`,
              label: "of net proceeds are yours",
              note: `Widgy keeps ${COMMISSION_PERCENT}%. Free widgets cost you nothing.`,
            },
            {
              value: `${POOL_PERCENT}%`,
              label: "of Widgy+ revenue to creators",
              note: "Shared monthly by active installs.",
            },
            {
              value: "100%",
              label: "of the rights stay with you",
              note: "Non-exclusive licence, revocable any time.",
            },
          ].map((stat) => (
            <div
              key={stat.label}
              className="flex flex-col gap-1 rounded-card border border-hairline bg-surface p-6 shadow-soft"
            >
              <span className="font-serif text-4xl font-semibold text-accent">
                {stat.value}
              </span>
              <span className="text-sm font-medium text-ink">{stat.label}</span>
              <span className="text-xs text-subtleText">{stat.note}</span>
            </div>
          ))}
        </section>

        {/* Worked example — the arithmetic, shown rather than asserted */}
        <section className="rounded-hero border border-hairline bg-surfaceMuted p-6">
          <h2 className="font-serif text-xl font-semibold text-ink">
            What a {usd(EXAMPLE.list)} widget actually pays
          </h2>
          <dl className="mt-4 flex flex-col gap-2 text-sm">
            {(
              [
                { label: "User pays", value: usd(EXAMPLE.list) },
                {
                  label: `Apple's fee (${APPLE_PERCENT}%)`,
                  value: `− ${usd(EXAMPLE.apple)}`,
                },
                { label: "Net proceeds", value: usd(EXAMPLE.net), strong: true },
                {
                  label: `Widgy commission (${COMMISSION_PERCENT}% of net)`,
                  value: `− ${usd(EXAMPLE.widgy)}`,
                },
              ] satisfies { label: string; value: string; strong?: boolean }[]
            ).map(({ label, value, strong }) => (
              <div
                key={label}
                className={`flex justify-between border-b border-hairline pb-2 ${
                  strong ? "font-medium text-ink" : "text-subtleText"
                }`}
              >
                <dt>{label}</dt>
                <dd className="tabular-nums">{value}</dd>
              </div>
            ))}
            <div className="flex justify-between pt-2 font-serif text-lg font-semibold text-ink">
              <dt>You receive</dt>
              <dd className="tabular-nums">
                {usd(EXAMPLE.creator)}{" "}
                <span className="text-sm font-normal text-subtleText">
                  ({EXAMPLE.creatorSharePercent}% of list)
                </span>
              </dd>
            </div>
          </dl>
        </section>

        {/* The document itself */}
        <section className="flex h-[520px] flex-col overflow-hidden rounded-hero border border-hairline bg-surface shadow-soft">
          <div className="flex items-center justify-between border-b border-hairline px-6 py-4">
            <h2 className="font-serif text-xl font-semibold text-ink">
              Widgy Creator Agreement
            </h2>
            <span className="text-xs text-subtleText">
              {readToEnd ? "Read in full" : "Scroll to the end"}
            </span>
          </div>
          <div
            ref={scroller}
            onScroll={handleScroll}
            className="flex flex-col gap-7 overflow-y-auto px-6 py-6"
          >
            {CLAUSES.map((clause) => (
              <article key={clause.title} className="flex flex-col gap-2">
                <h3 className="font-serif text-lg font-semibold text-ink">
                  {clause.title}
                </h3>
                {clause.paragraphs.map((text, i) => (
                  <p key={i} className="text-[15px] leading-relaxed text-subtleText">
                    {text}
                  </p>
                ))}
              </article>
            ))}
            <p className="border-t border-hairline pt-6 text-xs text-subtleText">
              End of agreement · Version {AGREEMENT_VERSION} · Effective{" "}
              {AGREEMENT_EFFECTIVE}. Questions before you sign:{" "}
              <a className="text-accent" href="mailto:creators@widgy.app">
                creators@widgy.app
              </a>
            </p>
          </div>
        </section>

        {/* Signature */}
        {submitted ? (
          <section className="flex flex-col items-center gap-4 rounded-hero border border-hairline bg-surface p-10 text-center shadow-soft">
            <span className="flex h-12 w-12 items-center justify-center rounded-full bg-accentTint font-serif text-xl text-accent">
              ✓
            </span>
            <h2 className="font-serif text-2xl font-semibold text-ink">
              Signed, {signature.trim()}.
            </h2>
            <p className="max-w-md text-subtleText">
              Version {AGREEMENT_VERSION}, accepted {today}. A copy is on your
              dashboard and in your inbox. You can submit a widget now.
            </p>
            <Link
              href="/submit"
              className="rounded-full bg-accent px-8 py-3 text-sm font-bold text-white transition-opacity hover:opacity-90"
            >
              Submit your first widget
            </Link>
          </section>
        ) : (
          <section className="flex flex-col gap-5 rounded-hero border border-hairline bg-surface p-6 shadow-soft">
            <div className="flex flex-col gap-2">
              <label
                htmlFor="signature"
                className="text-sm font-medium text-ink"
              >
                Full legal name
              </label>
              <input
                id="signature"
                value={signature}
                onChange={(e) => setSignature(e.target.value)}
                placeholder="As it should appear on the agreement"
                className="rounded-card border border-hairline bg-background px-4 py-3 text-ink outline-none transition-colors placeholder:text-subtleText/70 focus:border-accent"
              />
              <p className="text-xs text-subtleText">
                Typing your name here has the same effect as signing. Dated{" "}
                {today}.
              </p>
            </div>

            <label className="flex cursor-pointer items-start gap-3">
              <input
                type="checkbox"
                checked={agreed}
                onChange={(e) => setAgreed(e.target.checked)}
                className="mt-0.5 h-5 w-5 rounded border-hairline text-accent focus:ring-accent"
              />
              <span className="text-sm text-ink">
                I have read the agreement in full and accept it. I confirm the
                work I submit is mine to submit.
              </span>
            </label>

            <div className="flex flex-col items-start gap-3 border-t border-hairline pt-4 sm:flex-row sm:items-center sm:justify-between">
              <p className="text-xs text-subtleText">
                {!readToEnd
                  ? "Scroll to the end of the agreement to continue."
                  : !agreed
                    ? "Tick the box to continue."
                    : signature.trim().length <= 2
                      ? "Add your name to continue."
                      : "Ready to sign."}
              </p>
              <button
                type="button"
                disabled={!canAccept}
                onClick={() => setSubmitted(true)}
                className="rounded-full bg-accent px-8 py-3 text-sm font-bold text-white transition-all hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-40"
              >
                Accept &amp; continue
              </button>
            </div>
          </section>
        )}
      </main>
      <Footer />
    </>
  );
}

"use client";

import Image from "next/image";
import Link from "next/link";
import { useMemo, useState } from "react";
import NavBar from "@/components/NavBar";
import Footer from "@/components/Footer";
import StatusBadge from "@/components/StatusBadge";
import { previewSrc } from "@/lib/widgets";
import {
  COMMISSION_PERCENT,
  PAYOUT,
  POOL_PERCENT,
  usd,
  usdPrecise,
  worked,
} from "@/lib/terms";
import {
  CREATOR,
  INSTALL_HISTORY,
  LIFETIME_PAID_USD,
  POOL,
  WIDGETS,
  directEarnings,
  monthTotals,
  poolEarnings,
  poolRateUSD,
  poolTotalUSD,
  type CreatorWidget,
} from "@/lib/demo";

const PRICE_POINTS = [0.99, 1.99, 2.99, 4.99];

export default function DashboardPage() {
  // Local price overrides so the free/paid controls actually respond in the
  // demo. When the API lands this becomes a mutation instead of useState.
  const [prices, setPrices] = useState<Record<string, number | null>>(
    Object.fromEntries(WIDGETS.map((w) => [w.slug, w.priceUSD]))
  );

  const widgets = useMemo(
    () => WIDGETS.map((w) => ({ ...w, priceUSD: prices[w.slug] })),
    [prices]
  );

  const totals = monthTotals(widgets);
  const live = widgets.filter((w) => w.status === "approved");
  const activeInstalls = widgets.reduce((s, w) => s + w.totalInstalls, 0);
  const peak = Math.max(...INSTALL_HISTORY.map((m) => m.installs));

  const payoutDate = new Date();
  payoutDate.setMonth(payoutDate.getMonth() + 1, PAYOUT.netDays);

  const stats = [
    {
      label: "Earned in August",
      value: usd(totals.total),
      note: `${usd(totals.direct)} sales · ${usd(totals.pool)} pool`,
    },
    {
      label: "Paid to date",
      value: usd(LIFETIME_PAID_USD),
      note: `Next payout ${payoutDate.toLocaleDateString("en-GB", { day: "numeric", month: "short" })}`,
    },
    {
      label: "Total installs",
      value: activeInstalls.toLocaleString("en-US"),
      note: `${totals.poolInstalls.toLocaleString("en-US")} active with Widgy+ this month`,
    },
    {
      label: "Live widgets",
      value: `${live.length}`,
      note: `${widgets.length - live.length} in review or draft`,
    },
  ];

  return (
    <>
      <NavBar loggedIn />
      <main className="mx-auto max-w-container px-5 pb-24 pt-32 md:px-6">
        <header className="mb-10 flex flex-col justify-between gap-6 md:flex-row md:items-end">
          <div>
            <p className="text-sm font-medium text-subtleText">
              {CREATOR.handle} · creating since {CREATOR.joined}
            </p>
            <h1 className="mt-1 font-serif text-4xl font-semibold text-ink">
              Welcome back, {CREATOR.name.split(" ")[0]}
            </h1>
            <p className="mt-2 max-w-2xl text-subtleText">
              Everything your widgets did this month, and what you&apos;ll be
              paid for it.
            </p>
          </div>
          <Link
            href="/submit"
            className="flex w-fit items-center gap-2 rounded-full bg-accent px-6 py-3 text-sm font-bold text-white shadow-soft transition-opacity hover:opacity-90"
          >
            + New widget
          </Link>
        </header>

        {/* Headline numbers */}
        <section className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {stats.map((stat) => (
            <div
              key={stat.label}
              className="flex flex-col gap-1 rounded-card border border-hairline bg-surface p-6 shadow-soft"
            >
              <span className="text-xs font-bold uppercase tracking-wider text-subtleText">
                {stat.label}
              </span>
              <span className="font-serif text-3xl font-semibold text-ink">
                {stat.value}
              </span>
              <span className="text-xs text-subtleText">{stat.note}</span>
            </div>
          ))}
        </section>

        <div className="mb-8 grid grid-cols-1 gap-4 lg:grid-cols-5">
          {/* Where the money came from */}
          <section className="flex flex-col gap-5 rounded-hero border border-hairline bg-surface p-6 shadow-soft lg:col-span-2">
            <div>
              <h2 className="font-serif text-xl font-semibold text-ink">
                August earnings
              </h2>
              <p className="mt-1 text-sm text-subtleText">
                Two sources, calculated the way the agreement describes.
              </p>
            </div>

            <div className="flex flex-col gap-3">
              <EarningsRow
                title="Direct sales"
                amount={totals.direct}
                detail={`${totals.sales} purchases · ${usd(totals.grossOnSales)} gross, less Apple's fee and Widgy's ${COMMISSION_PERCENT}%`}
              />
              <EarningsRow
                title="Widgy+ creator pool"
                amount={totals.pool}
                detail={`${totals.poolInstalls.toLocaleString("en-US")} subscriber installs × ${usdPrecise(
                  poolRateUSD()
                )} per install`}
              />
            </div>

            <div className="flex items-baseline justify-between border-t border-hairline pt-4">
              <span className="font-medium text-ink">Total</span>
              <span className="font-serif text-2xl font-semibold text-ink">
                {usd(totals.total)}
              </span>
            </div>

            {/* The pool arithmetic, shown openly — this is the number creators
                are most likely to distrust, so it should be checkable. */}
            <div className="rounded-card bg-surfaceMuted p-4 text-xs leading-relaxed text-subtleText">
              <span className="font-bold uppercase tracking-wider">
                How the pool was worked out
              </span>
              <p className="mt-2">
                {POOL.month}: {usd(POOL.netSubscriptionUSD)} net Widgy+ revenue
                across the platform. {POOL_PERCENT}% of that —{" "}
                {usd(poolTotalUSD())} — went to creators, divided between{" "}
                {POOL.totalPoolInstalls.toLocaleString("en-US")} eligible
                installs. Yours were {totals.poolInstalls.toLocaleString("en-US")}{" "}
                of them.
              </p>
            </div>
          </section>

          {/* Installs over time */}
          <section className="flex flex-col gap-5 rounded-hero border border-hairline bg-surface p-6 shadow-soft lg:col-span-3">
            <div className="flex items-end justify-between">
              <div>
                <h2 className="font-serif text-xl font-semibold text-ink">
                  Installs
                </h2>
                <p className="mt-1 text-sm text-subtleText">
                  New installs per month across your live widgets.
                </p>
              </div>
              <span className="text-sm font-medium text-accent">
                +
                {Math.round(
                  ((INSTALL_HISTORY.at(-1)!.installs -
                    INSTALL_HISTORY.at(-2)!.installs) /
                    INSTALL_HISTORY.at(-2)!.installs) *
                    100
                )}
                % on July
              </span>
            </div>

            <div className="flex h-56 items-end gap-3">
              {INSTALL_HISTORY.map((month, i) => (
                <div
                  key={month.month}
                  className="group flex flex-1 flex-col items-center gap-2"
                >
                  <span className="text-xs font-medium text-subtleText opacity-0 transition-opacity group-hover:opacity-100">
                    {month.installs.toLocaleString("en-US")}
                  </span>
                  <div
                    className={`w-full rounded-t-lg transition-colors ${
                      i === INSTALL_HISTORY.length - 1
                        ? "bg-accent"
                        : "bg-accentTint group-hover:bg-accent/40"
                    }`}
                    style={{
                      height: `${Math.max((month.installs / peak) * 100, 2)}%`,
                    }}
                  />
                  <span className="text-xs text-subtleText">{month.month}</span>
                </div>
              ))}
            </div>
          </section>
        </div>

        {/* The widgets themselves */}
        <section className="flex flex-col gap-4">
          <div className="flex items-end justify-between">
            <h2 className="font-serif text-2xl font-semibold text-ink">
              My widgets
            </h2>
            <span className="text-sm text-subtleText">
              {widgets.length} submissions
            </span>
          </div>

          {widgets.map((widget) => (
            <WidgetRow
              key={widget.slug}
              widget={widget}
              onPrice={(price) =>
                setPrices((p) => ({ ...p, [widget.slug]: price }))
              }
            />
          ))}
        </section>

        {/* Payout */}
        <section className="mt-8 flex flex-col items-start justify-between gap-4 rounded-hero border border-hairline bg-surfaceMuted p-6 md:flex-row md:items-center">
          <div>
            <h2 className="font-serif text-xl font-semibold text-ink">
              Next payout · {usd(totals.total)}
            </h2>
            <p className="mt-1 max-w-xl text-sm text-subtleText">
              Sent to your account by{" "}
              {payoutDate.toLocaleDateString("en-GB", {
                day: "numeric",
                month: "long",
                year: "numeric",
              })}
              , {PAYOUT.netDays} days after the month closes. Balances under{" "}
              {usd(PAYOUT.thresholdUSD)} roll into the next month.
            </p>
          </div>
          <button
            type="button"
            className="shrink-0 rounded-full border border-accent px-6 py-3 text-sm font-bold text-accent transition-colors hover:bg-accentTint"
          >
            Payout settings
          </button>
        </section>
      </main>
      <Footer />
    </>
  );
}

function EarningsRow({
  title,
  amount,
  detail,
}: {
  title: string;
  amount: number;
  detail: string;
}) {
  return (
    <div className="flex items-start justify-between gap-4">
      <div>
        <p className="font-medium text-ink">{title}</p>
        <p className="mt-0.5 text-xs text-subtleText">{detail}</p>
      </div>
      <span className="shrink-0 font-serif text-lg font-semibold text-ink tabular-nums">
        {usd(amount)}
      </span>
    </div>
  );
}

function WidgetRow({
  widget,
  onPrice,
}: {
  widget: CreatorWidget;
  onPrice: (price: number | null) => void;
}) {
  const isLive = widget.status === "approved";
  const earnings = directEarnings(widget) + poolEarnings(widget);
  const split = widget.priceUSD ? worked(widget.priceUSD) : null;

  return (
    <article className="flex flex-col gap-5 rounded-card border border-hairline bg-surface p-4 shadow-soft transition-colors hover:border-subtleText/30 md:flex-row md:items-center md:justify-between md:p-6">
      <div className="flex items-center gap-4">
        <div className="h-20 w-20 shrink-0 overflow-hidden rounded-xl border border-hairline bg-surfaceMuted">
          <Image
            src={previewSrc(widget.slug)}
            alt={`${widget.name} preview`}
            width={600}
            height={600}
            sizes="80px"
            className="h-full w-full object-cover"
          />
        </div>
        <div>
          <h3 className="font-serif text-xl font-semibold text-ink">
            {widget.name}
          </h3>
          <p className="mt-1 text-sm text-subtleText">
            {widget.category} · submitted {widget.submitted}
          </p>
          {isLive && (
            <p className="mt-1 text-sm text-subtleText">
              {widget.totalInstalls.toLocaleString("en-US")} installs ·{" "}
              <span className="font-medium text-ink">{usd(earnings)}</span> this
              month
            </p>
          )}
        </div>
      </div>

      <div className="flex flex-col items-start gap-3 border-t border-hairline pt-4 md:items-end md:border-t-0 md:pt-0">
        <StatusBadge status={widget.status} />

        {isLive ? (
          <div className="flex flex-col items-start gap-1.5 md:items-end">
            <div className="flex flex-wrap items-center gap-1 rounded-lg bg-surfaceMuted p-1">
              <button
                type="button"
                onClick={() => onPrice(null)}
                className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
                  widget.priceUSD === null
                    ? "bg-surface text-ink shadow-soft"
                    : "text-subtleText hover:text-ink"
                }`}
              >
                Free
              </button>
              {PRICE_POINTS.map((price) => (
                <button
                  key={price}
                  type="button"
                  onClick={() => onPrice(price)}
                  className={`rounded-md px-3 py-1.5 text-sm font-medium tabular-nums transition-colors ${
                    widget.priceUSD === price
                      ? "bg-surface text-ink shadow-soft"
                      : "text-subtleText hover:text-ink"
                  }`}
                >
                  {usd(price)}
                </button>
              ))}
            </div>
            <p className="text-xs text-subtleText">
              {split
                ? `You keep ${usd(split.creator)} per sale (${split.creatorSharePercent}%)`
                : "Free widgets are commission-free and reach every user."}
            </p>
          </div>
        ) : (
          <button
            type="button"
            className="text-sm font-medium text-accent transition-opacity hover:opacity-70"
          >
            {widget.status === "changes-requested"
              ? "See review notes"
              : "View submission"}
          </button>
        )}
      </div>
    </article>
  );
}

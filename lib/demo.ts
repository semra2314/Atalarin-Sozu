// Demo data for the creator dashboard.
//
// Everything here is invented, and deliberately modest — a creator six months
// in with a few hundred installs, not a fantasy. It is kept in one file so the
// day the real API arrives, this file is the only thing that gets deleted.
//
// The money is *derived*, never typed: earnings come out of the same functions
// in lib/terms.ts that the agreement uses, so the dashboard can't quietly
// promise a split the contract doesn't.

import { COMMISSION_PERCENT, POOL_PERCENT, worked } from "./terms";
import type { SubmissionStatus } from "@/components/StatusBadge";

export type CreatorWidget = {
  slug: string;
  name: string;
  category: string;
  status: SubmissionStatus;
  submitted: string;
  /** Null when the widget is free. */
  priceUSD: number | null;
  /** Copies bought outright this month. */
  salesThisMonth: number;
  /** Widgy+ subscriber installs active this month — these draw from the pool. */
  poolInstallsThisMonth: number;
  totalInstalls: number;
};

export const CREATOR = {
  name: "Semra Yıldız",
  handle: "@semra",
  joined: "March 2026",
};

export const WIDGETS: CreatorWidget[] = [
  {
    slug: "aurora",
    name: "Aurora",
    category: "Clock",
    status: "approved",
    submitted: "14 Mar 2026",
    priceUSD: 2.99,
    salesThisMonth: 41,
    poolInstallsThisMonth: 386,
    totalInstalls: 2140,
  },
  {
    slug: "soz",
    name: "Söz",
    category: "Culture",
    status: "approved",
    submitted: "2 May 2026",
    priceUSD: null,
    salesThisMonth: 0,
    poolInstallsThisMonth: 0,
    totalInstalls: 3820,
  },
  {
    slug: "frame",
    name: "Frame",
    category: "Photography",
    status: "approved",
    submitted: "19 Jun 2026",
    priceUSD: 1.99,
    salesThisMonth: 23,
    poolInstallsThisMonth: 174,
    totalInstalls: 908,
  },
  {
    slug: "hush",
    name: "Hush",
    category: "Wellbeing",
    status: "in-review",
    submitted: "8 Aug 2026",
    priceUSD: null,
    salesThisMonth: 0,
    poolInstallsThisMonth: 0,
    totalInstalls: 0,
  },
  {
    slug: "orbit",
    name: "Orbit",
    category: "Clock",
    status: "changes-requested",
    submitted: "5 Aug 2026",
    priceUSD: 2.99,
    salesThisMonth: 0,
    poolInstallsThisMonth: 0,
    totalInstalls: 0,
  },
];

/** Installs across all of this creator's live widgets, month by month. */
export const INSTALL_HISTORY = [
  { month: "Feb", installs: 0 },
  { month: "Mar", installs: 210 },
  { month: "Apr", installs: 480 },
  { month: "May", installs: 735 },
  { month: "Jun", installs: 1120 },
  { month: "Jul", installs: 1490 },
  { month: "Aug", installs: 1860 },
];

/** The whole platform's Widgy+ pool for the month, and this creator's slice. */
export const POOL = {
  month: "August 2026",
  /** Net subscription revenue across the platform, after store fees. */
  netSubscriptionUSD: 8420,
  /** Total pool-eligible installs across every creator. */
  totalPoolInstalls: 24300,
};

export function directEarnings(widget: CreatorWidget) {
  if (!widget.priceUSD || widget.salesThisMonth === 0) return 0;
  return worked(widget.priceUSD).creator * widget.salesThisMonth;
}

export function poolTotalUSD() {
  return (POOL.netSubscriptionUSD * POOL_PERCENT) / 100;
}

/** What one pool-eligible install is worth this month. */
export function poolRateUSD() {
  return poolTotalUSD() / POOL.totalPoolInstalls;
}

export function poolEarnings(widget: CreatorWidget) {
  return widget.poolInstallsThisMonth * poolRateUSD();
}

export function widgetEarnings(widget: CreatorWidget) {
  return directEarnings(widget) + poolEarnings(widget);
}

/**
 * Takes the widget list rather than reading the constant, so that when the
 * dashboard's price controls change a widget the headline figures move with
 * them instead of quietly disagreeing.
 */
export function monthTotals(list: CreatorWidget[] = WIDGETS) {
  const direct = list.reduce((sum, w) => sum + directEarnings(w), 0);
  const pool = list.reduce((sum, w) => sum + poolEarnings(w), 0);
  const poolInstalls = list.reduce((sum, w) => sum + w.poolInstallsThisMonth, 0);
  const sales = list.reduce(
    (sum, w) => sum + (w.priceUSD ? w.salesThisMonth : 0),
    0
  );
  const grossOnSales = list.reduce(
    (sum, w) => sum + (w.priceUSD ?? 0) * w.salesThisMonth,
    0
  );
  return {
    direct,
    pool,
    total: direct + pool,
    poolInstalls,
    sales,
    grossOnSales,
    commissionKept: (grossOnSales * COMMISSION_PERCENT) / 100,
  };
}

/** Paid to date, before this month closes. */
export const LIFETIME_PAID_USD = 1284.6;

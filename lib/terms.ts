// The commercial terms, in one place.
//
// These numbers appear in the creator agreement, on the dashboard, and in the
// investor deck. Keeping them here means they can only be wrong in one place
// at a time. If a number changes, change it here and bump AGREEMENT_VERSION.

export const AGREEMENT_VERSION = "1.0";
export const AGREEMENT_EFFECTIVE = "12 August 2026";

/** Widgy's share of net proceeds on a paid widget sale. */
export const COMMISSION_PERCENT = 20;

/**
 * Apple's share of every in-app purchase. 15% under the App Store Small
 * Business Program, which Widgy qualifies for below $1M of annual proceeds;
 * 30% above it. We quote 15% because that is the rate in force today.
 */
export const APPLE_PERCENT = 15;

/** Share of net Widgy+ subscription revenue paid out to creators. */
export const POOL_PERCENT = 50;

export const SUBSCRIPTION = {
  monthlyUSD: 1.99,
  yearlyUSD: 14.99,
};

export const PAYOUT = {
  /** Balances below this roll into the following month. */
  thresholdUSD: 50,
  /** Days after the close of a calendar month that payouts are sent. */
  netDays: 30,
};

/**
 * A worked example, computed rather than typed, so the arithmetic on the page
 * can never drift from the rates above.
 *
 * The commission applies to net proceeds — what reaches Widgy after Apple's
 * fee — rather than to the list price. That way Apple's cut is shared in the
 * same proportion as the revenue, instead of landing entirely on the creator.
 */
export function worked(listPriceUSD: number) {
  const apple = (listPriceUSD * APPLE_PERCENT) / 100;
  const net = listPriceUSD - apple;
  const widgy = (net * COMMISSION_PERCENT) / 100;
  const creator = net - widgy;
  const round = (n: number) => Math.round(n * 100) / 100;
  return {
    list: round(listPriceUSD),
    apple: round(apple),
    net: round(net),
    widgy: round(widgy),
    creator: round(creator),
    creatorSharePercent: Math.round((creator / listPriceUSD) * 100),
  };
}

export const usd = (n: number) =>
  n.toLocaleString("en-US", { style: "currency", currency: "USD" });

/**
 * For per-install rates, which are fractions of a cent and would round to a
 * meaningless "$0.17" under the default two decimal places.
 */
export const usdPrecise = (n: number) =>
  n.toLocaleString("en-US", {
    style: "currency",
    currency: "USD",
    minimumFractionDigits: 4,
    maximumFractionDigits: 4,
  });

import Image from "next/image";
import Link from "next/link";
import NavBar from "@/components/NavBar";
import Footer from "@/components/Footer";

// Drop real exported widget preview PNGs into /public/widgets/ named after
// each widget below. Until then this renders a soft placeholder tile.
const SHOWCASE_WIDGETS = ["Aurora", "Drift", "Focus", "Frame", "Hush", "Ledger"];

const STEPS = [
  {
    number: 1,
    title: "Submit",
    description: "Name, description, and preview images.",
  },
  {
    number: 2,
    title: "Review & Approve",
    description: "Sign the agreement, and our team reviews your design.",
  },
  {
    number: 3,
    title: "Publish",
    description: "Choose free or paid and go live inside the Widgy app.",
  },
];

export default function LandingPage() {
  return (
    <>
      <NavBar />
      <main className="pt-20">
        {/* Hero */}
        <section className="mx-auto grid max-w-container grid-cols-1 items-center gap-10 px-5 py-20 md:grid-cols-2 md:px-6">
          <div className="flex flex-col gap-6">
            <h1 className="max-w-lg font-serif text-5xl font-semibold leading-tight text-ink">
              Design your widget. Share it with the world.
            </h1>
            <p className="max-w-md text-lg text-subtleText">
              Keep complete ownership of your designs. Choose to release them for
              free or set a price, all within the Widgy ecosystem.
            </p>
            <div className="mt-2 flex flex-wrap gap-4">
              <Link
                href="/submit"
                className="rounded-full bg-accent px-8 py-4 text-sm font-bold text-white transition-opacity hover:opacity-90"
              >
                Submit a Widget
              </Link>
              <Link
                href="#how-it-works"
                className="rounded-full border border-accent px-8 py-4 text-sm font-bold text-accent transition-colors hover:bg-accentTint"
              >
                How It Works
              </Link>
            </div>
          </div>

          <div className="relative flex justify-center">
            <div className="w-full max-w-sm rotate-2 rounded-hero border border-hairline bg-surface p-4 shadow-soft transition-transform duration-500 hover:rotate-0">
              <Image
                src="/hero-widget-collage.png"
                alt="A collage of Widgy home-screen widgets: weather, calendar, and a photo stack"
                width={1200}
                height={896}
                className="w-full rounded-card"
                priority
              />
            </div>
            <div className="absolute -right-10 -top-10 -z-10 h-64 w-64 rounded-full bg-accentTint blur-3xl" />
          </div>
        </section>

        {/* Widget showcase strip */}
        <section className="overflow-hidden bg-surfaceMuted py-20">
          <div className="mx-auto mb-6 max-w-container px-5 md:px-6">
            <h2 className="text-sm font-bold uppercase tracking-widest text-subtleText">
              Made by our creators
            </h2>
          </div>
          <div className="scrollbar-hide mx-auto flex max-w-container gap-6 overflow-x-auto px-5 pb-4 md:px-6">
            {SHOWCASE_WIDGETS.map((name) => (
              <div
                key={name}
                className="group flex shrink-0 flex-col items-center gap-2"
              >
                <div className="flex h-40 w-40 items-center justify-center rounded-hero border border-hairline bg-surface shadow-soft transition-transform duration-300 group-hover:-translate-y-2">
                  <span className="text-xs text-subtleText">preview</span>
                </div>
                <span className="font-serif text-sm font-semibold text-ink">
                  {name}
                </span>
              </div>
            ))}
          </div>
        </section>

        {/* How it works */}
        <section id="how-it-works" className="mx-auto max-w-container px-5 py-20 md:px-6">
          <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
            {STEPS.map((step) => (
              <div
                key={step.number}
                className="flex flex-col gap-4 rounded-hero border border-hairline bg-surface p-8 shadow-soft"
              >
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-accent text-sm font-bold text-white">
                  {step.number}
                </div>
                <h3 className="font-serif text-2xl font-semibold text-ink">
                  {step.title}
                </h3>
                <p className="text-subtleText">{step.description}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Trust band */}
        <section className="bg-surfaceMuted px-5 py-20 text-center">
          <div className="mx-auto flex max-w-2xl flex-col items-center gap-6">
            <h2 className="font-serif text-4xl font-semibold text-ink">
              Your work stays yours.
            </h2>
            <p className="text-subtleText">
              We believe creators should retain full ownership of their
              intellectual property. Our agreement is simple, transparent, and
              designed to protect your hard work while giving you a platform to
              share it.
            </p>
            <Link
              href="/agreement"
              className="border-b border-accent pb-1 text-sm font-medium text-accent transition-colors hover:opacity-80"
            >
              Read the Agreement
            </Link>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}

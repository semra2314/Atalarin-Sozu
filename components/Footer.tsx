import Link from "next/link";

export default function Footer() {
  return (
    <footer className="w-full bg-surfaceMuted py-10">
      <div className="mx-auto flex max-w-container flex-col items-center justify-between gap-4 px-5 md:flex-row md:px-6">
        <span className="font-serif text-lg font-semibold text-ink">Widgy</span>
        <nav className="flex flex-wrap justify-center gap-6 text-sm text-subtleText">
          <Link href="/agreement" className="transition-colors hover:text-accent">
            Creator Agreement
          </Link>
          <Link href="/submit" className="transition-colors hover:text-accent">
            Submit a Widget
          </Link>
          <Link href="/dashboard" className="transition-colors hover:text-accent">
            Dashboard
          </Link>
          <a
            href="mailto:creators@widgy.app"
            className="transition-colors hover:text-accent"
          >
            Contact
          </a>
        </nav>
        <span className="text-sm text-subtleText">
          © {new Date().getFullYear()} Widgy Creator Portal. All rights reserved.
        </span>
      </div>
    </footer>
  );
}

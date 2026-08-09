import Link from "next/link";

type NavBarProps = {
  /** Show the avatar + "My Dashboard" state instead of the "Submit a Widget" CTA. */
  loggedIn?: boolean;
};

export default function NavBar({ loggedIn = false }: NavBarProps) {
  return (
    <header className="fixed top-0 z-50 w-full border-b border-hairline bg-background/80 backdrop-blur-md">
      <div className="mx-auto flex h-20 max-w-container items-center justify-between px-5 md:px-6">
        <Link href="/" className="flex items-center gap-2">
          <span className="h-3 w-3 rounded-[3px] bg-accent" />
          <span className="font-serif text-2xl font-semibold text-ink">Widgy</span>
        </Link>

        <nav className="hidden items-center gap-8 md:flex">
          <Link
            href="/#how-it-works"
            className="text-sm font-medium text-subtleText transition-colors hover:text-accent"
          >
            How It Works
          </Link>
          <Link
            href="/agreement"
            className="text-sm font-medium text-subtleText transition-colors hover:text-accent"
          >
            Agreement
          </Link>
          <Link
            href="/#faq"
            className="text-sm font-medium text-subtleText transition-colors hover:text-accent"
          >
            FAQ
          </Link>
        </nav>

        {loggedIn ? (
          <div className="flex items-center gap-3">
            <Link
              href="/dashboard"
              className="hidden rounded-full bg-accent px-6 py-2.5 text-sm font-bold text-white transition-opacity hover:opacity-90 md:inline-flex"
            >
              My Dashboard
            </Link>
            <div className="h-10 w-10 rounded-full border-2 border-surfaceMuted bg-surfaceMuted" />
          </div>
        ) : (
          <Link
            href="/submit"
            className="hidden rounded-full bg-accent px-6 py-3 text-sm font-bold text-white transition-opacity hover:opacity-90 md:inline-flex"
          >
            Submit a Widget
          </Link>
        )}
      </div>
    </header>
  );
}

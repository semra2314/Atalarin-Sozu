import NavBar from "@/components/NavBar";
import Footer from "@/components/Footer";
import StatusBadge, { SubmissionStatus } from "@/components/StatusBadge";

type Submission = {
  id: string;
  name: string;
  category: string;
  date: string;
  status: SubmissionStatus;
};

// Replace with real data once the backend/API is wired up.
const SUBMISSIONS: Submission[] = [
  {
    id: "1",
    name: "Minimal Calendar",
    category: "Productivity",
    date: "Oct 12, 2024",
    status: "approved",
  },
  {
    id: "2",
    name: "Coral Weather",
    category: "Lifestyle",
    date: "Oct 14, 2024",
    status: "in-review",
  },
  {
    id: "3",
    name: "Photo Frame Pro",
    category: "Photography",
    date: "Oct 10, 2024",
    status: "changes-requested",
  },
];

const STATS = [
  { label: "Live Widgets", value: "12" },
  { label: "In Review", value: "3" },
  { label: "Total Views", value: "8.4k" },
];

export default function DashboardPage() {
  const hasSubmissions = SUBMISSIONS.length > 0;

  return (
    <>
      <NavBar loggedIn />
      <main className="mx-auto max-w-container px-5 py-20 md:px-6">
        <header className="mb-10 flex flex-col justify-between gap-6 md:flex-row md:items-end">
          <div>
            <h1 className="font-serif text-4xl font-semibold text-ink">
              My Widgets
            </h1>
            <p className="mt-2 max-w-2xl text-subtleText">
              Manage your creations, track performance, and submit new concepts
              to the Widgy ecosystem.
            </p>
          </div>
          <button
            type="button"
            className="flex w-fit items-center gap-2 rounded-full bg-accent px-6 py-3 text-sm font-bold text-white shadow-soft transition-colors hover:opacity-90"
          >
            + New Widget
          </button>
        </header>

        {/* Stats */}
        <section className="mb-16 grid grid-cols-1 gap-6 md:grid-cols-3">
          {STATS.map((stat) => (
            <div
              key={stat.label}
              className="flex flex-col justify-center rounded-xl border border-transparent bg-surfaceMuted p-8 transition-colors hover:border-hairline"
            >
              <span className="font-serif text-4xl font-semibold text-ink">
                {stat.value}
              </span>
              <span className="mt-1 text-xs font-bold uppercase tracking-wider text-subtleText">
                {stat.label}
              </span>
            </div>
          ))}
        </section>

        {/* Submissions list */}
        {hasSubmissions ? (
          <section className="flex flex-col gap-4">
            {SUBMISSIONS.map((submission) => (
              <div
                key={submission.id}
                className="flex flex-col items-start justify-between gap-4 rounded-card border border-hairline bg-surface p-4 shadow-soft transition-colors hover:border-subtleText/30 md:flex-row md:items-center md:p-6"
              >
                <div className="flex w-full items-center gap-4 md:w-auto">
                  <div className="h-20 w-20 shrink-0 rounded-lg bg-surfaceMuted" />
                  <div>
                    <h3 className="font-serif text-xl font-semibold text-ink">
                      {submission.name}
                    </h3>
                    <p className="mt-1 text-sm text-subtleText">
                      {submission.category} • {submission.date}
                    </p>
                  </div>
                </div>

                <div className="flex w-full items-center justify-between gap-4 border-t border-hairline pt-4 md:w-auto md:border-t-0 md:pt-0">
                  <StatusBadge status={submission.status} />
                  {submission.status === "approved" ? (
                    <div className="flex rounded-lg bg-surfaceMuted p-1">
                      <button className="rounded-md bg-surface px-4 py-1.5 text-sm font-medium text-ink shadow-soft">
                        Free
                      </button>
                      <button className="rounded-md px-4 py-1.5 text-sm font-medium text-subtleText transition-colors hover:text-ink">
                        Paid
                      </button>
                    </div>
                  ) : (
                    <button className="text-sm font-medium text-subtleText transition-colors hover:text-ink">
                      Edit
                    </button>
                  )}
                </div>
              </div>
            ))}
          </section>
        ) : (
          <section className="flex flex-col items-center gap-6 rounded-hero border-2 border-dashed border-hairline p-20 text-center">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-surfaceMuted text-2xl">
              □
            </div>
            <h3 className="font-serif text-2xl font-semibold text-ink">
              No widgets yet
            </h3>
            <p className="max-w-md text-subtleText">
              Ready to bring your ideas to life? Submit your first widget and
              share it with the Widgy community.
            </p>
            <a
              href="/submit"
              className="rounded-full bg-accent px-8 py-3 text-sm font-bold text-white transition-colors hover:opacity-90"
            >
              Submit Your First Widget
            </a>
          </section>
        )}
      </main>
      <Footer />
    </>
  );
}

export type SubmissionStatus = "approved" | "in-review" | "changes-requested";

const STYLES: Record<SubmissionStatus, { label: string; bg: string; text: string }> = {
  approved: { label: "Approved", bg: "bg-statusApprovedBg", text: "text-statusApproved" },
  "in-review": { label: "In Review", bg: "bg-statusPendingBg", text: "text-statusPending" },
  "changes-requested": {
    label: "Changes Requested",
    bg: "bg-statusDraftBg",
    text: "text-statusDraft",
  },
};

export default function StatusBadge({ status }: { status: SubmissionStatus }) {
  const style = STYLES[status];
  return (
    <span
      className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-bold uppercase tracking-wider ${style.bg} ${style.text}`}
    >
      {style.label}
    </span>
  );
}

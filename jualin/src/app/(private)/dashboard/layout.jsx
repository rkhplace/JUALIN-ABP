import DashboardGuard from "./DashboardGuard.jsx";

export default function DashboardLayout({ children }) {
  return (
    <div className="min-h-screen bg-[#fafafa]">
      <DashboardGuard>
        <div className="w-full">{children}</div>
      </DashboardGuard>
    </div>
  );
}

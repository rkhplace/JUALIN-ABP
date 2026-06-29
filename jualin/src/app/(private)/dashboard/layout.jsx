import DashboardGuard from "./DashboardGuard.jsx";
import DashboardBackground from "@/components/ui/DashboardBackground.jsx";

export default function DashboardLayout({ children }) {
  return (
    <div className="jualin-dashboard-bg min-h-screen">
      <DashboardBackground />
      <DashboardGuard>
        <div className="w-full">{children}</div>
      </DashboardGuard>
    </div>
  );
}

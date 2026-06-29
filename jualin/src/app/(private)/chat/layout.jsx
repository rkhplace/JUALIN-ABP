import ChatGuard from "./ChatGuard";
import DashboardBackground from "@/components/ui/DashboardBackground.jsx";

export default function ChatLayout({ children }) {
  return (
    <div className="jualin-dashboard-bg min-h-screen">
      <DashboardBackground />
      <div className="jualin-content-layer">
        <ChatGuard>{children}</ChatGuard>
      </div>
    </div>
  );
}

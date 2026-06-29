import React from "react";

export default function DashboardBackground() {
  return (
    <div className="dashboard-background" aria-hidden="true">
      <span className="dashboard-bg-red dashboard-bg-red-left" />
      <span className="dashboard-bg-red dashboard-bg-red-right" />

      <span className="dashboard-bg-paper dashboard-bg-paper-top" />
      <span className="dashboard-bg-paper dashboard-bg-paper-left" />
      <span className="dashboard-bg-paper dashboard-bg-paper-middle" />
      <span className="dashboard-bg-paper dashboard-bg-paper-right" />
      <span className="dashboard-bg-paper dashboard-bg-paper-bottom" />
    </div>
  );
}

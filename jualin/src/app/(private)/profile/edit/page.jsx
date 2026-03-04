"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/context/AuthProvider";
import Navbar from "@/components/ui/Navbar";
import { useProfileUpdate } from "@/hooks/profile/useProfileUpdate";
import { usePasswordChange } from "@/hooks/profile/usePasswordChange";
import usePaymentHistory from "@/hooks/payments/usePaymentHistory";
import { ProfileFormSection } from "../sections/profile-form";
import { PasswordChangeSection } from "../sections/password-change";
import { PurchaseHistorySection } from "../sections/purchase-history";
import { ProfileSidebarSection } from "../sections/profile-sidebar";

export default function EditProfilePage() {
  const { logout, user } = useAuth();
  const router = useRouter();

  const [activeTab, setActiveTab] = useState("edit");
  const [toast, setToast] = useState(null);

  const profileUpdate = useProfileUpdate();
  const passwordChange = usePasswordChange();
  const paymentHistory = usePaymentHistory();

  const handleCancel = () => {
    router.back();
  };

  const handleSaveProfile = async () => {
    const result = await profileUpdate.submit();

    if (result.success) {
      setToast({
        type: "success",
        message: result.message || "Profile updated",
      });
    } else {
      setToast({
        type: "error",
        message: result.message || "Failed to update",
      });
    }
  };

  const handlePasswordSubmit = async () => {
    const result = await passwordChange.submit();

    if (result.success) {
      setToast({ type: "success", message: result.message });
    } else {
      setToast({ type: "error", message: result.message });
    }

    return result;
  };

  const handleLogout = async () => {
    try {
      await logout();
    } catch (error) {
      console.error("Logout failed:", error);
    } finally {
      router.push("/auth/login");
    }
  };

  const handleExportCSV = () => {
    const data = paymentHistory.payments;
    if (!data || data.length === 0) {
      setToast({ type: "error", message: "No purchase history to export" });
      return;
    }

    const headers = ["Order ID", "Transaction Time", "Status", "Amount"];

    const csvRows = data.map((payment) => {
      const row = [
        `"${(payment.order_id || "").replace(/"/g, '""')}"`,
        payment.transaction_time
          ? new Date(payment.transaction_time).toLocaleString("id-ID")
          : "",
        `"${(payment.transaction_status || "").replace(/"/g, '""')}"`,
        payment.gross_amount || 0,
      ];
      return row.join(",");
    });

    const csvContent = [headers.join(","), ...csvRows].join("\n");

    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute(
      "download",
      `purchase_history_${new Date().toISOString().split("T")[0]}.csv`
    );
    link.style.visibility = "hidden";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    setToast({ type: "success", message: "CSV exported successfully" });
  };

  return (
    <div className="min-h-screen bg-white">
      <Navbar />

      <div className="flex">
        {/* Sidebar */}
        <ProfileSidebarSection
          activeTab={activeTab}
          onTabChange={setActiveTab}
          onLogout={handleLogout}
          role={user?.role}
        />

        {/* Main Content */}
        <div className="flex-1 bg-white">
          <div className="max-w-5xl mx-auto p-8">
            {activeTab === "edit" ? (
              <>
                {/* Header */}
                <div className="flex items-center justify-between mb-8">
                  <h1 className="text-2xl font-semibold text-[#1F1F1F]">
                    Edit Profile
                  </h1>
                  <div className="flex gap-3">
                    <button
                      onClick={handleSaveProfile}
                      disabled={profileUpdate.isLoading}
                      className="px-6 py-2 bg-[#E53935] hover:bg-[#D32F2F] text-white rounded-lg transition-all duration-200 shadow-md hover:shadow-lg focus:shadow-xl disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:shadow-md outline-none"
                    >
                      {profileUpdate.isLoading
                        ? "Saving..."
                        : "Simpan Perubahan"}
                    </button>
                  </div>
                </div>

                {/* Toast */}
                {toast && (
                  <div
                    className={`mb-6 rounded-lg p-4 shadow-md ${
                      toast.type === "success"
                        ? "bg-green-50 text-green-700 shadow-green-200"
                        : "bg-red-50 text-red-700 shadow-red-200"
                    }`}
                  >
                    {toast.message}
                  </div>
                )}

                {/* Profile Form Section */}
                <ProfileFormSection
                  form={profileUpdate.form}
                  errors={profileUpdate.errors}
                  imagePreview={profileUpdate.imagePreview}
                  onFieldChange={profileUpdate.updateField}
                  onImageSelect={profileUpdate.selectImage}
                />

                {/* Password Change Section */}
                <PasswordChangeSection
                  form={passwordChange.form}
                  errors={passwordChange.errors}
                  isLoading={passwordChange.isLoading}
                  onFieldChange={passwordChange.updateField}
                  onSubmit={handlePasswordSubmit}
                />
              </>
            ) : (
              <PurchaseHistorySection
                purchases={paymentHistory.paginated}
                totalAmount={paymentHistory.totalAmount}
                pagination={paymentHistory.pagination}
                formatCurrency={paymentHistory.formatCurrency}
                isLoading={paymentHistory.isLoading}
                onExport={handleExportCSV}
                onRefresh={paymentHistory.refetch}
              />
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

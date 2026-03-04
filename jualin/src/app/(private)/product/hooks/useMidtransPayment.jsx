import { useState } from "react";
import useMidtransSnap from "@/hooks/payments/useMidtransSnap";
import { transactionService, paymentService } from "@/services";

export default function useMidtransPayment() {
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState(null);
  const { loaded, openSnap } = useMidtransSnap();

  const showToast = (message, type = "info") => setToast({ message, type });

  const launchSnap = (snapToken, snapUrl) => {
    openSnap(snapToken, snapUrl, {
      onSuccess: () => showToast("Pembayaran berhasil", "success"),
      onPending: () =>
        showToast(
          "Pembayaran tertunda. Cek riwayat untuk melanjutkan.",
          "info"
        ),
      onError: () => showToast("Pembayaran gagal", "error"),
      onClose: () => showToast("Pembayaran dibatalkan", "info"),
    });
  };

  const waitForSnapIfNeeded = async () => {
    if (loaded || typeof window === "undefined") return;
    const script = document.getElementById("midtrans-snap-script");
    if (script) {
      await new Promise((resolve) =>
        script.addEventListener("load", resolve, { once: true })
      );
    }
  };

  const pay = async (product) => {
    if (!product || loading) return;
    setLoading(true);
    try {
      const user = JSON.parse(localStorage.getItem("user") || "{}");

      const trx = await transactionService.create({
        seller_id: product.seller_id,
        items: [{ product_id: product.id, quantity: 1 }],
      });
      const transactionId = trx?.id || trx?.data?.id;
      if (!transactionId) throw new Error("Gagal membuat transaksi");

      const payPayload = await paymentService.createOrContinuePayment(
        transactionId,
        {
          first_name: user.username || "User",
          last_name: user.username || "User",
          email: user.email || "user@example.com",
          phone: "081234567890",
        }
      );

      const snapToken = payPayload?.snap_token;
      const snapUrl = payPayload?.snap_url;
      if (!snapToken && !snapUrl)
        throw new Error("Token pembayaran tidak tersedia");

      await waitForSnapIfNeeded();
      launchSnap(snapToken, snapUrl);
    } catch (err) {
      showToast(err.message || "Failed to process payment", "error");
    } finally {
      setLoading(false);
    }
  };

  const continuePayment = async (transactionId) => {
    if (!transactionId || loading) return;
    setLoading(true);
    try {
      const user = JSON.parse(localStorage.getItem("user") || "{}");
      const payPayload = await paymentService.createOrContinuePayment(
        transactionId,
        {
          first_name: user.username || "User",
          last_name: user.username || "User",
          email: user.email || "user@example.com",
          phone: "081234567890",
        }
      );

      const snapToken = payPayload?.snap_token;
      const snapUrl = payPayload?.snap_url;
      if (!snapToken && !snapUrl)
        throw new Error("Token pembayaran tidak tersedia");

      await waitForSnapIfNeeded();
      launchSnap(snapToken, snapUrl);
    } catch (err) {
      showToast(err.message || "Gagal melanjutkan pembayaran", "error");
    } finally {
      setLoading(false);
    }
  };

  const resumePayment = async (snapToken, snapUrl) => {
    if (loading) return;
    if (!snapToken && !snapUrl) {
      showToast("Token pembayaran tidak valid", "error");
      return;
    }

    setLoading(true);
    try {
      await waitForSnapIfNeeded();
      launchSnap(snapToken, snapUrl);
    } catch (err) {
      showToast("Gagal memuat popup pembayaran", "error");
    } finally {
      setLoading(false);
    }
  };

  return { pay, continuePayment, resumePayment, loading, toast, setToast };
}

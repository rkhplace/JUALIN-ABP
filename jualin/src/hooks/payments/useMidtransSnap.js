import { useEffect, useState } from "react";

export default function useMidtransSnap() {
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;

    const existing = document.getElementById("midtrans-snap-script");
    if (existing) {
      setLoaded(true);
      return;
    }

    const script = document.createElement("script");
    script.id = "midtrans-snap-script";
    script.src = "https://app.sandbox.midtrans.com/snap/snap.js";
    script.setAttribute(
      "data-client-key",
      process.env.NEXT_PUBLIC_MIDTRANS_CLIENT_KEY || ""
    );
    script.async = true;
    script.onload = () => setLoaded(true);
    document.body.appendChild(script);
  }, []);

  const openSnap = (snapToken, snapUrl, callbacks) => {
    if (typeof window === "undefined") return;
    const cb = callbacks || {};

    const runPay = () => {
      try {
        window.snap.pay(snapToken, cb);
      } catch (e) {
        if (snapUrl) {
          window.open(snapUrl, "_blank");
        } else {
          console.error("snap.pay error:", e);
        }
      }
    };

    if (window.snap && snapToken) {
      runPay();
      return;
    }
    const script = document.getElementById("midtrans-snap-script");
    if (script && snapToken) {
      if (!window.snap) {
        script.addEventListener(
          "load",
          () => {
            if (window.snap) runPay();
            else if (snapUrl) window.open(snapUrl, "_blank");
          },
          { once: true }
        );
      } else {
        runPay();
      }
      return;
    }

    if (snapUrl) {
      window.open(snapUrl, "_blank");
    } else {
      throw new Error("Snap not available");
    }
  };

  return { loaded, openSnap };
}

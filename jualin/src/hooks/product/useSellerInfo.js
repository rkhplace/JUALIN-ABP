import { useEffect, useRef } from "react";
import { useAsync } from "../common/useAsync";
import { userService } from "@/services/user/userService";

export const useSellerInfo = (sellerId) => {
  const {
    data: seller,
    loading,
    error,
    execute,
  } = useAsync(
    () => (sellerId ? userService.fetchById(sellerId) : Promise.resolve(null)),
    { immediate: false, initialData: null }
  );

  const lastIdRef = useRef(null);
  useEffect(() => {
    if (!sellerId) return;
    if (lastIdRef.current !== sellerId) {
      lastIdRef.current = sellerId;
      execute();
    }
  }, [sellerId, execute]);

  return { seller, isLoading: loading, error, refetch: execute };
};

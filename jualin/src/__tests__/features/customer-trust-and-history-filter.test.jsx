import React from "react";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import ProductDetailSection from "@/app/(private)/product/sections/detail";
import { PurchaseHistorySection } from "@/app/(private)/profile/sections/purchase-history";
import { AuthContext } from "@/context/AuthProvider";

jest.mock("@/context/AuthProvider", () => {
  const React = require("react");
  const AuthContext = React.createContext(null);

  return {
    AuthContext,
    useAuth: () => React.useContext(AuthContext),
  };
});

jest.mock("next/navigation", () => ({
  useRouter: () => ({ push: jest.fn() }),
}));

jest.mock("@/context/ChatProvider", () => ({
  ChatContext: React.createContext({ startChat: jest.fn() }),
}));

jest.mock("@/app/(private)/product/hooks/useMidtransPayment", () => () => ({
  pay: jest.fn(),
  resumePayment: jest.fn(),
  loading: false,
  toast: null,
  setToast: jest.fn(),
}));

jest.mock("@/services", () => ({
  escrowService: {
    refundPayment: jest.fn(),
  },
  transactionService: {
    payWallet: jest.fn(),
  },
}));

jest.mock("@/services/backoffice/reportService", () => ({
  reportService: {
    createReport: jest.fn(),
  },
}));

const product = {
  id: 10,
  name: "Sepeda Balap",
  description: "Sepeda terawat",
  seller_id: 22,
  category: "Hobi",
  price: 4800000,
  stock: 2,
  image: [],
};

const seller = {
  id: 22,
  username: "seller_celsyka",
  is_verified: true,
};

describe("Customer verified seller notice", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  test("shows once for a customer and verified seller pair", async () => {
    const authValue = { user: { id: 7, role: "customer" } };
    const { unmount } = render(
      <AuthContext.Provider value={authValue}>
        <ProductDetailSection product={product} seller={seller} />
      </AuthContext.Provider>
    );

    expect(
      await screen.findByRole("dialog", { name: "Penjual Terverifikasi" })
    ).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Mengerti" }));
    await waitFor(() =>
      expect(
        screen.queryByRole("dialog", { name: "Penjual Terverifikasi" })
      ).not.toBeInTheDocument()
    );
    unmount();

    render(
      <AuthContext.Provider value={authValue}>
        <ProductDetailSection product={product} seller={seller} />
      </AuthContext.Provider>
    );

    expect(
      screen.queryByRole("dialog", { name: "Penjual Terverifikasi" })
    ).not.toBeInTheDocument();
  });

  test("does not show for an unverified seller", () => {
    render(
      <AuthContext.Provider value={{ user: { id: 7, role: "customer" } }}>
        <ProductDetailSection
          product={product}
          seller={{ ...seller, is_verified: false }}
        />
      </AuthContext.Provider>
    );

    expect(
      screen.queryByRole("dialog", { name: "Penjual Terverifikasi" })
    ).not.toBeInTheDocument();
  });
});

describe("Purchase history status filter", () => {
  test("applies the selected status from the filter modal", () => {
    const onStatusFilterChange = jest.fn();

    render(
      <AuthContext.Provider value={{ updateUser: jest.fn() }}>
        <PurchaseHistorySection
          purchases={[]}
          totalAmount={0}
          filteredCount={2}
          statusFilter="all"
          onStatusFilterChange={onStatusFilterChange}
          pagination={{
            currentPage: 1,
            totalPages: 1,
            itemsPerPage: 10,
            setItemsPerPage: jest.fn(),
            goToPage: jest.fn(),
            next: jest.fn(),
            prev: jest.fn(),
          }}
          formatCurrency={(value) => `Rp ${value}`}
          isLoading={false}
          onExport={jest.fn()}
          onRefresh={jest.fn()}
        />
      </AuthContext.Provider>
    );

    fireEvent.click(
      screen.getByRole("button", { name: "Filter riwayat pembelian" })
    );
    fireEvent.click(screen.getByRole("button", { name: "Selesai" }));
    fireEvent.click(screen.getByRole("button", { name: "Terapkan" }));

    expect(onStatusFilterChange).toHaveBeenCalledWith("completed");
  });
});

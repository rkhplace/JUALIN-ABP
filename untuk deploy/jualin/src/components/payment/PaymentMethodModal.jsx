import React from "react";
import { formatCurrency } from "@/utils/formatters/currency";
import { CreditCard, Wallet } from "lucide-react";

export default function PaymentMethodModal({
    isOpen,
    onClose,
    onConfirm,
    walletBalance,
    productPrice,
}) {
    const [selectedMethod, setSelectedMethod] = React.useState("wallet");

    const isWalletSufficient = Number(walletBalance) >= Number(productPrice);

    // Auto-select gateway if wallet is insufficient and user hasn't actively tried to override it
    React.useEffect(() => {
        if (!isWalletSufficient && selectedMethod === "wallet") {
            setSelectedMethod("gateway");
        }
    }, [isWalletSufficient, selectedMethod]);

    if (!isOpen) return null;

    const handleConfirm = () => {
        onConfirm(selectedMethod);
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <div
                className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200"
                role="dialog"
                aria-modal="true"
            >
                <div className="bg-red-600 px-6 py-4 flex justify-between items-center rounded-t-2xl">
                    <h3 className="text-lg font-bold text-white">Select Payment Method</h3>
                    <button
                        onClick={onClose}
                        className="text-white hover:text-red-200 transition-colors p-1 rounded-full hover:bg-red-700"
                    >
                        <span className="sr-only">Close</span>
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <div className="p-6 space-y-4">
                    {/* Wallet Balance Option */}
                    <label
                        className={`
              flex items-start p-4 border rounded-xl cursor-pointer transition-all duration-200
              ${selectedMethod === "wallet" ? "border-red-500 bg-red-50 ring-2 ring-red-500/20" : "border-gray-200 hover:border-red-300 hover:bg-gray-50"}
              ${!isWalletSufficient ? "opacity-60 cursor-not-allowed bg-gray-50" : ""}
            `}
                    >
                        <div className="flex items-center h-6">
                            <input
                                type="radio"
                                name="paymentMethod"
                                value="wallet"
                                className="w-5 h-5 text-red-600 bg-gray-100 border-gray-300 focus:ring-red-500 cursor-pointer"
                                checked={selectedMethod === "wallet"}
                                onChange={() => isWalletSufficient && setSelectedMethod("wallet")}
                                disabled={!isWalletSufficient}
                            />
                        </div>
                        <div className="ml-4 flex-1">
                            <div className="flex items-center gap-2">
                                <Wallet className={`w-5 h-5 ${selectedMethod === 'wallet' ? 'text-red-600' : 'text-gray-500'}`} />
                                <span className="block text-sm font-semibold text-gray-900">
                                    Wallet Balance (Saldo Jualin)
                                </span>
                            </div>
                            <span className={`block text-sm mt-1 ${isWalletSufficient ? 'text-gray-500' : 'text-red-500'}`}>
                                Your balance: <span className="font-bold">{formatCurrency(walletBalance || 0)}</span>
                            </span>
                            {!isWalletSufficient && (
                                <span className="block text-xs text-red-500 mt-1.5 font-medium bg-red-50 p-1.5 rounded w-fit">
                                    Insufficient balance
                                </span>
                            )}
                        </div>
                    </label>

                    {/* Payment Gateway Option */}
                    <label
                        className={`
              flex items-start p-4 border rounded-xl cursor-pointer transition-all duration-200
              ${selectedMethod === "gateway" ? "border-red-500 bg-red-50 ring-2 ring-red-500/20" : "border-gray-200 hover:border-red-300 hover:bg-gray-50"}
            `}
                    >
                        <div className="flex items-center h-6">
                            <input
                                type="radio"
                                name="paymentMethod"
                                value="gateway"
                                className="w-5 h-5 text-red-600 bg-gray-100 border-gray-300 focus:ring-red-500 cursor-pointer"
                                checked={selectedMethod === "gateway"}
                                onChange={() => setSelectedMethod("gateway")}
                            />
                        </div>
                        <div className="ml-4 flex-1">
                            <div className="flex items-center gap-2">
                                <CreditCard className={`w-5 h-5 ${selectedMethod === 'gateway' ? 'text-red-600' : 'text-gray-500'}`} />
                                <span className="block text-sm font-semibold text-gray-900">
                                    Payment Gateway
                                </span>
                            </div>
                            <span className="block text-sm text-gray-500 mt-1">
                                Pay via Midtrans (Bank Transfer, E-Wallet, etc)
                            </span>
                        </div>
                    </label>
                </div>

                <div className="p-6 bg-gray-50 border-t border-gray-100">
                    <div className="flex justify-between items-end mb-4">
                        <span className="text-gray-600 text-sm font-medium">Product price:</span>
                        <span className="text-xl font-bold text-gray-900">{formatCurrency(productPrice)}</span>
                    </div>
                    <button
                        onClick={handleConfirm}
                        className="w-full text-white bg-red-600 hover:bg-red-700 focus:ring-4 focus:outline-none focus:ring-red-300 font-bold rounded-xl text-md px-5 py-3.5 text-center shadow-md transition-all duration-200 transform hover:-translate-y-0.5"
                    >
                        Pay Now
                    </button>
                </div>
            </div>
        </div>
    );
}

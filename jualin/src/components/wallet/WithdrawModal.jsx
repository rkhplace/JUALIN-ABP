import React, { useState } from "react";
import { formatCurrency } from "@/utils/formatters/currency";

export default function WithdrawModal({ isOpen, onClose, onConfirm, walletBalance }) {
    const [amount, setAmount] = useState("");
    const [bankName, setBankName] = useState("");
    const [accountNumber, setAccountNumber] = useState("");
    const [accountName, setAccountName] = useState("");

    if (!isOpen) return null;

    const numAmount = Number(amount);
    const isAmountValid = numAmount > 0;
    const isInsufficient = numAmount > Number(walletBalance);

    const isFormValid =
        isAmountValid && !isInsufficient && bankName.trim() && accountNumber.trim() && accountName.trim();

    const handleSubmit = (e) => {
        e.preventDefault();
        if (isFormValid) {
            onConfirm({
                amount: numAmount,
                bank_name: bankName.trim(),
                account_number: accountNumber.trim(),
                account_name: accountName.trim(),
            });
        }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
            <div
                className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200"
                role="dialog"
                aria-modal="true"
            >
                <div className="bg-red-600 px-6 py-4 flex justify-between items-center rounded-t-2xl">
                    <h3 className="text-lg font-bold text-white">Withdraw Balance</h3>
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

                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    <div className="bg-red-50 text-red-800 p-4 rounded-xl border border-red-100 flex justify-between items-center">
                        <span className="font-semibold text-sm">Current Balance:</span>
                        <span className="font-bold text-xl">{formatCurrency(walletBalance)}</span>
                    </div>

                    <div className="space-y-3">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Bank Name</label>
                            <input
                                type="text"
                                value={bankName}
                                onChange={(e) => setBankName(e.target.value)}
                                placeholder="e.g. BCA, Mandiri, BRI"
                                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none transition-all"
                                required
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Account Number</label>
                            <input
                                type="text"
                                value={accountNumber}
                                onChange={(e) => setAccountNumber(e.target.value)}
                                placeholder="1234567890"
                                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none transition-all"
                                required
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Account Holder Name</label>
                            <input
                                type="text"
                                value={accountName}
                                onChange={(e) => setAccountName(e.target.value)}
                                placeholder="John Doe"
                                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none transition-all"
                                required
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Withdraw Amount</label>
                            <div className="relative">
                                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 font-medium">Rp</span>
                                <input
                                    type="number"
                                    value={amount}
                                    onChange={(e) => setAmount(e.target.value)}
                                    placeholder="0"
                                    min="1"
                                    className={`w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 outline-none transition-all ${isInsufficient
                                            ? "border-red-500 focus:ring-red-500 focus:border-red-500"
                                            : "border-gray-300 focus:ring-red-500 focus:border-red-500"
                                        }`}
                                    required
                                />
                            </div>
                            {isInsufficient && (
                                <p className="mt-1 text-sm text-red-600 font-medium">Insufficient wallet balance</p>
                            )}
                        </div>
                    </div>

                    <div className="pt-4 flex gap-3">
                        <button
                            type="button"
                            onClick={onClose}
                            className="flex-1 px-4 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-800 font-semibold rounded-xl transition-colors"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={!isFormValid}
                            className="flex-1 px-4 py-2.5 bg-red-600 hover:bg-red-700 disabled:bg-red-300 disabled:cursor-not-allowed text-white font-semibold rounded-xl transition-colors shadow-sm"
                        >
                            Withdraw
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}

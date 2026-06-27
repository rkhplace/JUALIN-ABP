import React, { useState } from "react";
import { formatCurrency } from "@/utils/formatters/currency";

const BANK_OPTIONS = [
    "Bank Aladin Syariah",
    "Bank Amar Indonesia",
    "Bank Artha Graha Internasional",
    "Bank BCA Syariah",
    "Bank BJB",
    "Bank BJB Syariah",
    "Bank BNI",
    "Bank BRI",
    "Bank BRI Agroniaga (BRI Agro)",
    "Bank BSI (Bank Syariah Indonesia)",
    "Bank BTN",
    "Bank BTN Syariah",
    "Bank Bukopin",
    "Bank CIMB Niaga",
    "Bank Danamon Indonesia",
    "Bank DKI",
    "Bank INA Perdana",
    "Bank Jago",
    "Bank Jambi",
    "Bank Jateng",
    "Bank Jatim",
    "Bank Kalbar",
    "Bank Kalsel",
    "Bank Kalteng",
    "Bank Kaltimtara",
    "Bank Lampung",
    "Bank Mandiri",
    "Bank Mayapada",
    "Bank Maybank Indonesia",
    "Bank Mega",
    "Bank Muamalat Indonesia",
    "Bank Nagari",
    "Bank Neo Commerce",
    "Bank NTT",
    "Bank OCBC",
    "Bank Panin Bank",
    "Bank Papua",
    "Bank Permata",
    "Bank Raya Indonesia",
    "Bank Riau Kepri Syariah",
    "Bank Sinarmas",
    "Bank Sulselbar",
    "Bank Sultra",
    "Bank Sulteng",
    "Bank Sumsel Babel",
    "Bank Sumut",
    "Bank UOB Indonesia",
    "Bank Victoria International",
    "Bank Woori Saudara",
    "SeaBank Indonesia",
    "Superbank Indonesia",
];

export default function WithdrawModal({ isOpen, onClose, onConfirm, walletBalance }) {
    const [amount, setAmount] = useState("");
    const [bankName, setBankName] = useState("");
    const [isBankListOpen, setIsBankListOpen] = useState(false);
    const [accountNumber, setAccountNumber] = useState("");
    const [accountName, setAccountName] = useState("");

    if (!isOpen) return null;

    const numAmount = Number(amount);
    const isAmountValid = numAmount > 0;
    const isInsufficient = numAmount > Number(walletBalance);

    const isFormValid =
        isAmountValid && !isInsufficient && bankName.trim() && accountNumber.trim() && accountName.trim();

    const handleAmountChange = (e) => {
        const digits = e.target.value.replace(/\D/g, "");
        setAmount(digits.replace(/^0+(?=\d)/, ""));
    };

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
                className="bg-white rounded-2xl shadow-xl w-full max-w-md animate-in fade-in zoom-in-95 duration-200"
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
                            <div className="relative">
                                <button
                                    type="button"
                                    onClick={() => setIsBankListOpen((current) => !current)}
                                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-red-500 focus:border-red-500 outline-none transition-all bg-white text-left flex items-center justify-between gap-3"
                                    aria-haspopup="listbox"
                                    aria-expanded={isBankListOpen}
                                >
                                    <span className={bankName ? "text-gray-900" : "text-gray-400"}>
                                        {bankName || "Pilih bank tujuan"}
                                    </span>
                                    <svg
                                        className={`w-4 h-4 text-gray-500 transition-transform ${isBankListOpen ? "rotate-180" : ""}`}
                                        fill="none"
                                        viewBox="0 0 24 24"
                                        stroke="currentColor"
                                    >
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                                    </svg>
                                </button>

                                {isBankListOpen && (
                                    <div
                                        className="absolute z-20 mt-2 w-full overflow-hidden rounded-xl border border-gray-200 bg-white shadow-xl ring-1 ring-black/5"
                                        role="listbox"
                                    >
                                        <div className="max-h-56 overflow-y-auto scroll-smooth py-1">
                                            {BANK_OPTIONS.map((bank) => (
                                                <button
                                                    key={bank}
                                                    type="button"
                                                    onClick={() => {
                                                        setBankName(bank);
                                                        setIsBankListOpen(false);
                                                    }}
                                                    className={`w-full px-4 py-2.5 text-left text-sm transition-colors hover:bg-red-50 hover:text-red-700 ${bankName === bank
                                                            ? "bg-red-50 font-semibold text-red-700"
                                                            : "text-gray-700"
                                                        }`}
                                                    role="option"
                                                    aria-selected={bankName === bank}
                                                >
                                                    {bank}
                                                </button>
                                            ))}
                                        </div>
                                    </div>
                                )}
                            </div>
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
                                    type="text"
                                    inputMode="numeric"
                                    value={amount ? Number(amount).toLocaleString("id-ID") : ""}
                                    onChange={handleAmountChange}
                                    placeholder="0"
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

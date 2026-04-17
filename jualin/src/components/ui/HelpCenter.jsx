"use client";
import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import {
    MessageCircle,
    X,
    AlertTriangle,
    User,
    Send,
    HelpCircle,
    LogIn
} from "lucide-react";
import { reportService } from "@/services/backoffice/reportService";
import { useAuth } from "@/context/AuthProvider";
import { toast } from "sonner";

export default function HelpCenter() {
    const router = useRouter();
    const { user, loading } = useAuth();
    const [isOpen, setIsOpen] = useState(false);
    const [formData, setFormData] = useState({
        username: "",
        type: "",
        targetUsername: "",
        description: "",
    });
    const [errors, setErrors] = useState({});
    const [isSubmitting, setIsSubmitting] = useState(false);

    // Auto-populate username saat modal dibuka atau user berubah
    useEffect(() => {
        if (isOpen && user?.username && !formData.username) {
            setFormData((prev) => ({
                ...prev,
                username: user.username,
            }));
        }
    }, [isOpen, user?.username, formData.username]);

    // Check authentication saat mencoba membuka help center
    // Redirect ke login jika user logout saat modal terbuka
    useEffect(() => {
        if (isOpen && !user && !loading) {
            setIsOpen(false);
            toast.error("Sesi Anda telah berakhir. Silakan login kembali.");
            router.push("/auth/login");
        }
    }, [user, loading, isOpen, router]);

    const handleHelpCenterClick = () => {
        // Jika user belum login, redirect ke halaman login
        if (!user) {
            router.push("/auth/login");
            toast.info("Silakan login terlebih dahulu untuk menggunakan Pusat Bantuan");
            return;
        }
        // Jika sudah login, buka modal
        setIsOpen(!isOpen);
    };

    const toggleOpen = () => setIsOpen(!isOpen);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData((prev) => ({
            ...prev,
            [name]: value,
        }));
        // Clear error when user types
        if (errors[name]) {
            setErrors((prev) => ({ ...prev, [name]: "" }));
        }
    };

    const validate = () => {
        const newErrors = {};
        // Username sudah auto-filled dari user yang login, skip validasi
        if (!formData.type) newErrors.type = "Tipe pelaporan wajib dipilih";

        if (formData.type === "Laporan Pengguna") {
            if (!formData.targetUsername.trim()) {
                newErrors.targetUsername = "Username yang melanggar wajib diisi";
            }
            if (!formData.description.trim()) {
                newErrors.description = "Deskripsi pelanggaran wajib diisi";
            }
        } else {
            if (formData.type && !formData.description.trim()) {
                newErrors.description = "Deskripsi laporan wajib diisi";
            }
        }

        setErrors(newErrors);
        return Object.keys(newErrors).length === 0;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validate()) return;

        setIsSubmitting(true);

        const promise = reportService.createReport(formData);

        toast.promise(promise, {
            loading: 'Mengirim laporan...',
            success: () => {
                setIsOpen(false);
                setFormData({
                    username: "",
                    type: "",
                    targetUsername: "",
                    description: "",
                });
                return "Laporan berhasil dikirim! Terima kasih atas masukan Anda.";
            },
            error: (err) => {
                console.error(err);
                return "Gagal mengirim laporan. Silakan coba lagi.";
            }
        });

        try {
            await promise;
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <>
            {/* Floating Button - Hanya tampil jika user sudah login */}
            {!loading && user && (
                <button
                    onClick={handleHelpCenterClick}
                    className={`fixed bottom-6 right-6 z-50 p-4 rounded-full shadow-lg transition-transform hover:scale-105 active:scale-95 bg-[#E83030] text-white flex items-center justify-center`}
                    aria-label="Pusat Bantuan"
                    title="Pusat Bantuan - Hanya untuk pengguna yang login"
                >
                    {isOpen ? <X size={28} /> : <HelpCircle size={28} />}
                </button>
            )}

            {/* Modal Overlay - Hanya tampil jika user sudah login dan modal dibuka */}
            {isOpen && !loading && user && (
                <div
                    className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in"
                    onClick={toggleOpen}
                >
                    {/* Modal Content */}
                    <div
                        className="relative w-full max-w-[500px] bg-white rounded-2xl shadow-2xl overflow-hidden animate-slide-in-from-bottom"
                        onClick={(e) => e.stopPropagation()}
                    >
                        {/* Header */}
                        <div className="bg-gradient-to-r from-gray-50 to-white px-6 py-5 border-b border-gray-100 flex justify-between items-start">
                            <div>
                                <h2 className="text-xl font-bold text-gray-900">Pusat Bantuan</h2>
                                <p className="text-sm text-gray-500 mt-1">Laporkan masalah atau berikan feedback</p>
                            </div>
                            <button
                                onClick={toggleOpen}
                                className="text-gray-400 hover:text-gray-600 transition-colors p-1"
                            >
                                <X size={20} />
                            </button>
                        </div>

                        {/* Form */}
                        <form onSubmit={handleSubmit} className="p-6 max-h-[70vh] overflow-y-auto custom-scrollbar">
                            <div className="space-y-5">
                                {/* Username Pelapor */}
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1.5 flex items-center gap-2">
                                        <span>Username Anda</span>
                                        {formData.username && (
                                            <span className="inline-flex items-center gap-1 px-2 py-1 bg-green-50 text-green-700 text-xs font-medium rounded-full">
                                                <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                                                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                                                </svg>
                                                Terdeteksi
                                            </span>
                                        )}
                                    </label>
                                    <input
                                        type="text"
                                        name="username"
                                        value={formData.username}
                                        disabled
                                        className="w-full px-4 py-2.5 rounded-lg border border-gray-200 bg-gray-50 text-gray-600 cursor-not-allowed focus:outline-none transition-all"
                                        placeholder="Username akan terdeteksi otomatis"
                                    />
                                    <p className="text-xs text-gray-500 mt-1.5 ml-1">Username Anda telah terdeteksi otomatis dari akun yang login</p>
                                </div>

                                {/* Tipe Pelaporan */}
                                <div>
                                    <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                                        Tipe Laporan <span className="text-red-500">*</span>
                                    </label>
                                    <div className="relative">
                                        <select
                                            name="type"
                                            value={formData.type}
                                            onChange={handleChange}
                                            className={`w-full px-4 py-2.5 rounded-lg border ${errors.type ? 'border-red-500 bg-red-50' : 'border-gray-200'} focus:outline-none focus:border-[#E83030] focus:ring-4 focus:ring-red-100 appearance-none bg-white cursor-pointer`}
                                        >
                                            <option value="">Pilih tipe laporan...</option>
                                            <option value="Laporan Pengguna">🚨 Laporan Pengguna (Pelanggaran)</option>
                                            <option value="Bug">🐛 Bug / Masalah Teknis</option>
                                            <option value="Feedback">💡 Saran / Feedback</option>
                                            <option value="Lainnya">📝 Lainnya</option>
                                        </select>
                                        <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-gray-500">
                                            <svg width="12" height="12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
                                            </svg>
                                        </div>
                                    </div>
                                    {errors.type && <p className="text-xs text-red-500 mt-1 ml-1">{errors.type}</p>}
                                </div>

                                {/* Conditional Fields for "Laporan Pengguna" */}
                                {formData.type === "Laporan Pengguna" && (
                                    <div className="animate-fade-in space-y-5 bg-orange-50 p-4 rounded-xl border border-orange-100">
                                        <div className="flex items-center gap-3 text-orange-800 mb-2">
                                            <div className="p-2 bg-white rounded-full shadow-sm">
                                                <User size={18} className="text-orange-600" />
                                            </div>
                                            <div className="text-sm font-medium">Detail Pelanggaran User</div>
                                        </div>

                                        <div>
                                            <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                                                Username Pelanggar <span className="text-red-500">*</span>
                                            </label>
                                            <input
                                                type="text"
                                                name="targetUsername"
                                                value={formData.targetUsername}
                                                onChange={handleChange}
                                                className={`w-full px-4 py-2.5 rounded-lg border ${errors.targetUsername ? 'border-red-500' : 'border-gray-200'} focus:outline-none focus:border-[#E83030] focus:ring-4 focus:ring-red-100 bg-white`}
                                                placeholder="Contoh: user123"
                                            />
                                            {errors.targetUsername && <p className="text-xs text-red-500 mt-1 ml-1">{errors.targetUsername}</p>}
                                        </div>

                                        <div>
                                            <label className="block text-sm font-semibold text-gray-700 mb-1.5 flex justify-between">
                                                <span>Deskripsi Pelanggaran <span className="text-red-500">*</span></span>
                                                <span className="text-xs font-normal text-gray-400">{formData.description.length} chars</span>
                                            </label>
                                            <textarea
                                                name="description"
                                                rows="3"
                                                value={formData.description}
                                                onChange={handleChange}
                                                className={`w-full px-4 py-2.5 rounded-lg border ${errors.description ? 'border-red-500' : 'border-gray-200'} focus:outline-none focus:border-[#E83030] focus:ring-4 focus:ring-red-100 bg-white resize-none`}
                                                placeholder="Jelaskan detail pelanggaran..."
                                            />
                                            {errors.description && <p className="text-xs text-red-500 mt-1 ml-1">{errors.description}</p>}
                                        </div>
                                    </div>
                                )}

                                {/* Default Description Field for other types */}
                                {formData.type !== "Laporan Pengguna" && formData.type !== "" && (
                                    <div className="animate-fade-in">
                                        <label className="block text-sm font-semibold text-gray-700 mb-1.5">
                                            Deskripsi Laporan <span className="text-red-500">*</span>
                                        </label>
                                        <textarea
                                            name="description"
                                            rows="4"
                                            value={formData.description}
                                            onChange={handleChange}
                                            className={`w-full px-4 py-2.5 rounded-lg border ${errors.description ? 'border-red-500' : 'border-gray-200'} focus:outline-none focus:border-[#E83030] focus:ring-4 focus:ring-red-100 resize-none`}
                                            placeholder="Ceritakan detail masalah atau saran Anda..."
                                        />
                                        {errors.description && <p className="text-xs text-red-500 mt-1 ml-1">{errors.description}</p>}
                                    </div>
                                )}
                            </div>

                            {/* Action Buttons */}
                            <div className="flex gap-3 pt-4 mt-2">
                                <button
                                    type="button"
                                    onClick={toggleOpen}
                                    className="flex-1 px-4 py-2.5 rounded-xl border border-gray-200 text-gray-600 font-medium hover:bg-gray-50 transition-colors"
                                    disabled={isSubmitting}
                                >
                                    Batal
                                </button>
                                <button
                                    type="submit"
                                    disabled={isSubmitting}
                                    className="flex-1 px-4 py-2.5 rounded-xl bg-[#E83030] text-white font-medium shadow-lg shadow-red-200 hover:shadow-xl hover:-translate-y-0.5 active:scale-95 transition-all disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                                >
                                    {isSubmitting ? (
                                        <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                    ) : (
                                        <>
                                            <Send size={18} /> Kirim Laporan
                                        </>
                                    )}
                                </button>
                            </div>
                        </form>

                        {/* Footer Info */}
                        <div className="bg-gray-50 px-6 py-4 border-t border-gray-100">
                            <div className="flex gap-3">
                                <AlertTriangle size={20} className="text-amber-500 shrink-0 mt-0.5" />
                                <div className="text-xs text-gray-500 leading-relaxed">
                                    <strong className="text-gray-700 block mb-1">Informasi Penting</strong>
                                    Laporan Anda akan ditinjau oleh tim admin kami dalam waktu <strong>1-2 hari kerja</strong>. Terima kasih telah membantu menjaga komunitas Jualin tetap aman.
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </>
    );
}

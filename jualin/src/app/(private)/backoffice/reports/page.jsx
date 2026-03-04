"use client";

import { useEffect, useState } from "react";
import { reportService } from "@/services/backoffice/reportService";
import { toast } from "sonner";
import ConfirmationModal from "@/components/ui/ConfirmationModal";
import { Loader2, AlertCircle, MessageSquareWarning, CheckCircle, XCircle } from "lucide-react";

export default function ReportsPage() {
    const [reports, setReports] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [currentPage, setCurrentPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);

    const fetchReports = async (page) => {
        setLoading(true);
        try {
            const response = await reportService.getReports(page);
            if (response.success) {
                // response.data contains the array of reports directly (see ApiResponse.php helper)
                setReports(response.data);
                // Pagination data is in response.pagination
                setCurrentPage(response.pagination?.current_page || 1);
                setTotalPages(response.pagination?.last_page || 1);
            } else {
                setError("Gagal memuat laporan");
            }
        } catch (err) {
            setError(err.message || "Terjadi kesalahan saat memuat laporan");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchReports(currentPage);
    }, [currentPage]);

    const getTypeBadge = (type) => {
        switch (type) {
            case "Bug":
                return <span className="px-2 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-700">Bug</span>;
            case "Feedback":
                return <span className="px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-700">Feedback</span>;
            case "Laporan Pengguna":
                return <span className="px-2 py-1 text-xs font-semibold rounded-full bg-orange-100 text-orange-700">Pelanggaran</span>;
            default:
                return <span className="px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-700">{type}</span>;
        }
    };

    const [confirmModal, setConfirmModal] = useState({
        isOpen: false,
        type: null, // "danger" or null
        title: "",
        message: "",
        onConfirm: () => { },
    });

    const closeConfirmModal = () => {
        setConfirmModal((prev) => ({ ...prev, isOpen: false }));
    };

    const handleUpdateStatus = (id, newStatus) => {
        setConfirmModal({
            isOpen: true,
            type: newStatus === 'rejected' ? 'danger' : null,
            title: newStatus === 'accepted' ? 'Terima Laporan' : 'Tolak Laporan',
            message: `Apakah Anda yakin ingin mengubah status laporan ini menjadi "${newStatus}"?`,
            onConfirm: () => {
                executeStatusUpdate(id, newStatus);
                closeConfirmModal();
            },
        });
    };

    const executeStatusUpdate = async (id, newStatus) => {
        const promise = reportService.updateStatus(id, newStatus);

        toast.promise(promise, {
            loading: 'Mengupdate status...',
            success: () => {
                // Optimistic update
                setReports(reports.map(r => r.id === id ? { ...r, status: newStatus } : r));
                return "Status berhasil diperbarui";
            },
            error: (err) => err.message || "Gagal mengupdate status"
        });
    };

    return (
        <div className="p-8 max-w-7xl mx-auto">
            {/* ... (keep header) ... */}
            <div className="flex items-center justify-between mb-8">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Laporan Pengguna</h1>
                    <p className="text-gray-500 mt-1">Daftar laporan masalah dan feedback dari pengguna</p>
                </div>
            </div>

            {loading ? (
                <div className="flex justify-center items-center h-64">
                    <Loader2 className="w-8 h-8 animate-spin text-[#E83030]" />
                </div>
            ) : error ? (
                <div className="bg-red-50 p-4 rounded-xl flex items-center gap-3 text-red-700 border border-red-100">
                    <AlertCircle size={20} />
                    {error}
                </div>
            ) : (
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead className="bg-gray-50 border-b border-gray-100">
                                <tr>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tanggal</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Pelapor</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tipe</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Detail</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
                                    <th className="px-6 py-4 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">Aksi</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-gray-100">
                                {reports.length > 0 ? (
                                    reports.map((report) => (
                                        <tr key={report.id} className="hover:bg-gray-50 transition-colors">
                                            <td className="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
                                                {new Date(report.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                                            </td>
                                            <td className="px-6 py-4 text-sm font-medium text-gray-900">
                                                {report.username}
                                            </td>
                                            <td className="px-6 py-4">
                                                {getTypeBadge(report.type)}
                                            </td>
                                            <td className="px-6 py-4 text-sm text-gray-600 max-w-xs">
                                                {report.target_username && (
                                                    <div className="text-xs font-semibold text-orange-600 mb-1">Target: {report.target_username}</div>
                                                )}
                                                <p className="truncate" title={report.description}>{report.description}</p>
                                            </td>
                                            <td className="px-6 py-4">
                                                <span className={`px-2 py-1 text-xs font-semibold rounded-full capitalize ${report.status === 'accepted' ? 'bg-green-100 text-green-700' :
                                                    report.status === 'rejected' ? 'bg-red-100 text-red-700' :
                                                        report.status === 'processed' ? 'bg-blue-100 text-blue-700' :
                                                            'bg-yellow-100 text-yellow-700'
                                                    }`}>
                                                    {report.status}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 text-right">
                                                {report.status === 'pending' && (
                                                    <div className="flex justify-end gap-2">
                                                        <button
                                                            onClick={() => handleUpdateStatus(report.id, 'accepted')}
                                                            className="p-1 text-green-500 hover:bg-green-50 rounded-full transition-colors"
                                                            title="Terima"
                                                        >
                                                            <CheckCircle size={20} />
                                                        </button>
                                                        <button
                                                            onClick={() => handleUpdateStatus(report.id, 'rejected')}
                                                            className="p-1 text-red-500 hover:bg-red-50 rounded-full transition-colors"
                                                            title="Tolak"
                                                        >
                                                            <XCircle size={20} />
                                                        </button>
                                                    </div>
                                                )}
                                            </td>
                                        </tr>
                                    ))
                                ) : (
                                    <tr>
                                        <td colSpan="5" className="px-6 py-12 text-center text-gray-500">
                                            <div className="flex flex-col items-center gap-3">
                                                <div className="p-3 bg-gray-100 rounded-full">
                                                    <MessageSquareWarning size={24} className="text-gray-400" />
                                                </div>
                                                <p>Belum ada laporan yang masuk</p>
                                            </div>
                                        </td>
                                    </tr>
                                )}
                            </tbody>
                        </table>
                    </div>

                    {/* Pagination */}
                    <div className="px-6 py-4 border-t border-gray-100 flex items-center justify-between">
                        <button
                            onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                            disabled={currentPage === 1}
                            className="px-3 py-1.5 rounded-lg border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            Previous
                        </button>
                        <span className="text-sm text-gray-500">
                            Page {currentPage} of {totalPages}
                        </span>
                        <button
                            onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                            disabled={currentPage === totalPages}
                            className="px-3 py-1.5 rounded-lg border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            Next
                        </button>
                    </div>
                </div>
            )}
            {/* Confirmation Modal */}
            <ConfirmationModal
                isOpen={confirmModal.isOpen}
                onClose={closeConfirmModal}
                onConfirm={confirmModal.onConfirm}
                title={confirmModal.title}
                message={confirmModal.message}
                isDanger={confirmModal.type === 'danger'}
                confirmText={confirmModal.type === 'danger' ? 'Tolak' : 'Terima'}
            />
        </div>
    );
}

"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { reportService } from "@/services/backoffice/reportService";
import { userService } from "@/services/user/userService";
import { toast } from "sonner";
import ConfirmationModal from "@/components/ui/ConfirmationModal";
import { Loader2, AlertCircle, MessageSquareWarning, CheckCircle, XCircle } from "lucide-react";

const BAN_DURATION_OPTIONS = [
    { value: "1", label: "1 hari" },
    { value: "7", label: "7 hari" },
    { value: "30", label: "30 hari" },
];

export default function ReportsPage() {
    const [reports, setReports] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [currentPage, setCurrentPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [banDurations, setBanDurations] = useState({});
    const [banningReportId, setBanningReportId] = useState(null);
    const [statusSelections, setStatusSelections] = useState({});

    const fetchReports = async (page) => {
        setLoading(true);
        try {
            const response = await reportService.getReports(page);
            if (response.success) {
                // response.data contains the array of reports directly (see ApiResponse.php helper)
                setReports(response.data);
                setStatusSelections(response.data.reduce((acc, report) => ({
                    ...acc,
                    [report.id]: getUIStatusValue(report.status),
                }), {}));
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
            case "Pelanggaran User":
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

    const getReporterUsername = (report) => report.reporter_username || report.username || "-";
    const getReportedUsername = (report) => report.reported_username || report.target_username || null;
    const getReportedProductName = (report) => report.reported_product_name || report.product?.name || null;

    const getUIStatusValue = (status) => {
        if (status === 'reviewed') return 'accepted';
        if (status === 'resolved') return 'rejected';
        if (status === 'processed') return 'processing';
        return status;
    };

    const formatReportStatus = (status) => {
        switch (status) {
            case 'pending':
                return 'Menunggu';
            case 'processing':
            case 'processed':
                return 'Diproses';
            case 'reviewed':
            case 'accepted':
                return 'Diterima';
            case 'resolved':
            case 'rejected':
                return 'Ditolak';
            default:
                return status;
        }
    };

    const handleUpdateStatus = async (id, newStatus) => {
        setStatusSelections((prev) => ({ ...prev, [id]: newStatus }));
        await executeStatusUpdate(id, newStatus);
    };

    const executeStatusUpdate = async (id, newStatus) => {
        const promise = reportService.updateStatus(id, newStatus);

        toast.promise(promise, {
            loading: 'Mengupdate status...',
            success: (response) => {
                const updatedStatus = response?.data?.status || newStatus;
                const uiStatus = getUIStatusValue(updatedStatus);

                setReports((currentReports) => currentReports.map((report) => (
                    report.id === id ? { ...report, status: updatedStatus } : report
                )));
                setStatusSelections((prev) => ({ ...prev, [id]: uiStatus }));
                return "Status berhasil diperbarui";
            },
            error: (err) => err.message || "Gagal mengupdate status"
        });
    };

    const handleBanUser = (report) => {
        const durationDays = banDurations[report.id] || "1";
        const reportedUsername = getReportedUsername(report);
        const durationLabel = BAN_DURATION_OPTIONS.find((option) => option.value === durationDays)?.label || `${durationDays} hari`;

        if (!reportedUsername) {
            toast.error("Akun pelanggar tidak tersedia untuk laporan ini.");
            return;
        }

        setConfirmModal({
            isOpen: true,
            type: 'danger',
            title: 'Ban Akun',
            message: `Ban akun "${reportedUsername}" selama ${durationLabel}? Akun tidak dapat login sampai masa ban berakhir.`,
            onConfirm: () => {
                executeBanUser(report.id, durationDays);
                closeConfirmModal();
            },
        });
    };

    const executeBanUser = async (id, durationDays) => {
        setBanningReportId(id);
        
        const report = reports.find(r => r.id === id);
        if (!report || !report.reported_user_id) {
            toast.error("User ID tidak ditemukan untuk laporan ini");
            setBanningReportId(null);
            return;
        }

        const promise = userService
            .banUser(report.reported_user_id, durationDays)
            .finally(() => setBanningReportId(null));

        toast.promise(promise, {
            loading: 'Memproses ban akun...',
            success: (response) => {
                const bannedUntil = response?.data?.banned_until
                    ? `${new Date(response.data.banned_until).toLocaleDateString('id-ID', { year: 'numeric', month: 'short', day: 'numeric' })} ${new Date(response.data.banned_until).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}`
                    : null;

                setReports((currentReports) => currentReports.map((report) => (
                    report.id === id
                        ? {
                            ...report,
                            reported_user_is_banned: true,
                            reported_user_banned_until: response?.data?.banned_until || null,
                        }
                        : report
                )));

                return bannedUntil
                    ? `Akun berhasil diban sampai ${bannedUntil}`
                    : 'Akun berhasil diban';
            },
            error: (err) => err.message || "Gagal memproses ban akun",
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
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Akun Pelanggar / Terlapor</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Tipe</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Detail</th>
                                    <th className="px-6 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">Status</th>
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
                                                {getReporterUsername(report)}
                                            </td>
                                            <td className="px-6 py-4 text-sm font-medium text-orange-700">
                                                {getReportedUsername(report) || "Tidak tersedia"}
                                            </td>
                                            <td className="px-6 py-4">
                                                {getTypeBadge(report.type)}
                                            </td>
                                            <td className="px-6 py-4 text-sm text-gray-600 max-w-xs">
                                                {(getReporterUsername(report) || getReportedUsername(report)) && (
                                                    <div className="mb-1 space-y-0.5 text-xs">
                                                        <div className="text-gray-500">Pelapor: <span className="font-semibold text-gray-700">{getReporterUsername(report)}</span></div>
                                                        <div className="text-orange-600">Terlapor: <span className="font-semibold">{getReportedUsername(report) || "Tidak tersedia"}</span></div>
                                                    </div>
                                                )}
                                                {getReportedProductName(report) && (
                                                    <div className="mb-1 text-xs">
                                                        <span className="text-gray-500">Produk: </span>
                                                        <Link href={`/backoffice/products/${report.product?.id ?? report.reported_product_id}/edit`} className="font-semibold text-[#E83030] hover:underline">
                                                            {getReportedProductName(report)}
                                                        </Link>
                                                    </div>
                                                )}
                                                <p className="truncate" title={report.description}>{report.description}</p>
                                            </td>
                                            <td className="px-6 py-4">
                                                <select
                                                    value={statusSelections[report.id] ?? getUIStatusValue(report.status)}
                                                    onChange={(event) => handleUpdateStatus(report.id, event.target.value)}
                                                    className={`h-9 rounded-lg border px-3 text-xs font-medium focus:outline-none focus:ring-2 focus:ring-[#E83030]/20 ${
                                                        report.status === 'reviewed' || report.status === 'accepted' ? 'border-green-200 bg-green-50 text-green-700' :
                                                        report.status === 'resolved' || report.status === 'rejected' ? 'border-red-200 bg-red-50 text-red-700' :
                                                        report.status === 'processed' || (statusSelections[report.id] ?? getUIStatusValue(report.status)) === 'processing' ? 'border-blue-200 bg-blue-50 text-blue-700' :
                                                        'border-yellow-200 bg-yellow-50 text-yellow-700'
                                                    }`}
                                                    aria-label={`Status laporan untuk laporan ${report.id}`}
                                                >
                                                    <option value="pending">Menunggu</option>
                                                    <option value="processing">Diproses</option>
                                                    <option value="accepted">Diterima</option>
                                                    <option value="rejected">Ditolak</option>
                                                </select>
                                            </td>
                                        </tr>
                                    ))
                                ) : (
                                    <tr>
                                        <td colSpan="6" className="px-6 py-12 text-center text-gray-500">
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
                confirmText={confirmModal.title === 'Ban Akun' ? 'Ban' : confirmModal.type === 'danger' ? 'Tolak' : 'Terima'}
            />
        </div>
    );
}

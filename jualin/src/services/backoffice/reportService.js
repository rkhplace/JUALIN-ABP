import axios from "axios";
import Cookies from "js-cookie";

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";
const API_URL = BASE_URL.endsWith('/api/v1') ? BASE_URL : `${BASE_URL}/api/v1`;

const getAuthHeaders = () => {
    const token = (typeof window !== "undefined" ? localStorage.getItem("token") : null) || Cookies.get("token");
    return token ? { Authorization: `Bearer ${token}` } : {};
};

const throwServiceError = (error) => {
    const data = error.response?.data;
    const serviceError = new Error(data?.message || error.message || "Request failed");
    serviceError.errors = data?.errors || null;
    serviceError.statusCode = error.response?.status || data?.status_code || null;
    throw serviceError;
};

export const reportService = {
    // Create new report (public or auth)
    createReport: async (data) => {
        try {
            const response = await axios.post(`${API_URL}/reports`, data, {
                headers: {
                    ...getAuthHeaders(),
                    "Content-Type": "application/json",
                },
            });
            return response.data;
        } catch (error) {
            throwServiceError(error);
        }
    },

    // Get all reports (admin only)
    getReports: async (page = 1) => {
        try {
            const response = await axios.get(`${API_URL}/reports?page=${page}`, {
                headers: getAuthHeaders(),
            });
            return response.data;
        } catch (error) {
            throwServiceError(error);
        }
    },

    // Update report status (admin only)
    updateStatus: async (id, status) => {
        try {
            const response = await axios.patch(`${API_URL}/reports/${id}/status`, { status }, {
                headers: getAuthHeaders(),
            });
            return response.data;
        } catch (error) {
            throwServiceError(error);
        }
    }
};

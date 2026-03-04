import axios from "axios";
import Cookies from "js-cookie";

export class ApiError extends Error {
  constructor(
    message,
    statusCode,
    originalError,
    errors = null,
    details = null
  ) {
    super(message);
    this.name = "ApiError";
    this.statusCode = statusCode;
    this.originalError = originalError;
    this.errors = errors;
    this.details = details;
  }
}
const parseApiError = (error) => {
  const respData = error?.response?.data || {};
  const status = error?.response?.status ?? respData?.status_code;
  const message = respData?.message || error?.message || "Unknown error";
  const errors = respData?.errors || null;
  return new ApiError(message, status, error, errors, respData);
};

const getToken = () => {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("token") || Cookies.get("token") || null;
};

const instance = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000",
  headers: { "Content-Type": "application/json" },
  timeout: 20000,
});

instance.interceptors.request.use((config) => {
  const token = getToken();
  if (token && config.headers && !config.headers.Authorization) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

instance.interceptors.response.use(
  (res) => res,
  (error) => {
    const status = error?.response?.status;
    const cfg = error?.config || {};
    const url = (cfg.url || "").toString();
    const skip =
      cfg.skipAuthRedirect === true ||
      cfg.headers?.["X-Skip-Auth-Redirect"] === "true" ||
      url.includes("/api/v1/login") ||
      url.includes("/api/v1/register") ||
      url.includes("/api/v1/refresh");
    if (typeof window !== "undefined" && status === 401 && !skip) {
      localStorage.removeItem("token");
      localStorage.removeItem("user");
      Cookies.remove("token");
      Cookies.remove("role");
      window.location.href = "/auth/login";
    }
    return Promise.reject(error);
  }
);

export const fetcher = {
  async get(
    url,
    { params, headers, auth = true, skipAuthRedirect = false } = {}
  ) {
    try {
      const res = await instance.get(url, {
        params,
        headers:
          auth === false
            ? { ...(headers || {}), Authorization: undefined }
            : headers,
        skipAuthRedirect,
      });
      return res.data;
    } catch (err) {
      throw parseApiError(err);
    }
  },
  async post(
    url,
    data,
    { headers, auth = true, skipAuthRedirect = false } = {}
  ) {
    try {
      const res = await instance.post(url, data, {
        headers:
          auth === false
            ? { ...(headers || {}), Authorization: undefined }
            : headers,
        skipAuthRedirect,
      });
      return res.data;
    } catch (err) {
      throw parseApiError(err);
    }
  },
  async patch(url, data, { headers, auth = true } = {}) {
    try {
      const res = await instance.patch(url, data, {
        headers:
          auth === false
            ? { ...(headers || {}), Authorization: undefined }
            : headers,
      });
      return res.data;
    } catch (err) {
      throw parseApiError(err);
    }
  },
  async put(url, data, { headers, auth = true } = {}) {
    try {
      const res = await instance.put(url, data, {
        headers:
          auth === false
            ? { ...(headers || {}), Authorization: undefined }
            : headers,
      });
      return res.data;
    } catch (err) {
      throw parseApiError(err);
    }
  },
  async delete(url, { headers, auth = true } = {}) {
    try {
      const res = await instance.delete(url, {
        headers:
          auth === false
            ? { ...(headers || {}), Authorization: undefined }
            : headers,
      });
      return res.data;
    } catch (err) {
      throw parseApiError(err);
    }
  },
  async upload(url, formData, { headers, auth = true } = {}) {
    try {
      const res = await instance.post(url, formData, {
        headers: {
          ...(auth === false ? { Authorization: undefined } : {}),
          ...(headers || {}),
          "Content-Type": "multipart/form-data",
        },
      });
      return res.data;
    } catch (err) {
      throw parseApiError(err);
    }
  },
};

export default fetcher;

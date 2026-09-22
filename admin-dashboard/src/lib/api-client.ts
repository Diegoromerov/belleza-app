import axios, { AxiosInstance, AxiosError } from 'axios';

// IMPORTANTE: Tu backend está en puerto 3000
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

export interface GetBookingsFilters {
  rol?: 'cliente' | 'prestador' | 'ADMIN';
  [key: string]: unknown;
}

export interface SendMessagePayload {
  message: string;
  image_path?: string;
}

export interface UpdateProfilePayload {
  full_name?: string;
  phone?: string;
  description?: string;
  active_start_hour?: number | null;
  active_end_hour?: number | null;
  weekly_schedule?: unknown;
  [key: string]: unknown;
}

/** Limpia la sesión del cliente (localStorage + cookies que lee el middleware). */
function clearClientSession() {
  if (typeof window === 'undefined') return;
  localStorage.removeItem('glow_token');
  localStorage.removeItem('glow_user');
  localStorage.removeItem('adminToken');
  document.cookie = 'glow_token=; path=/; max-age=0; SameSite=Lax';
  document.cookie = 'adminToken=; path=/; max-age=0; SameSite=Lax';
}

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: API_URL,
      timeout: 10000,
      headers: { 'Content-Type': 'application/json' },
    });

    // Interceptor para agregar token
    this.client.interceptors.request.use((config) => {
      if (typeof window !== 'undefined') {
        const token = localStorage.getItem('glow_token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
      }
      return config;
    });

    // Interceptor para errores
    this.client.interceptors.response.use(
      (response) => response,
      (error: AxiosError) => {
        if (error.response?.status === 401 && typeof window !== 'undefined') {
          clearClientSession();
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  // Bookings
  // El backend NO expone GET /api/bookings: solo /bookings/provider y /bookings/client
  // (ver backend/src/routes/bookingRoutes.js).
  async getBookings(filters?: GetBookingsFilters) {
    const { rol, ...params } = filters || {};
    const path = rol === 'prestador' ? '/api/bookings/provider' : '/api/bookings/client';
    const response = await this.client.get(path, { params });
    const payload = response.data;
    if (Array.isArray(payload)) return payload;
    if (payload && Array.isArray(payload.data)) return payload.data;
    return [];
  }

  async cancelBooking(id: number) {
    const response = await this.client.patch(`/api/bookings/${id}/cancel`);
    return response.data;
  }

  // Services
  async getServices() {
    const response = await this.client.get('/api/services');
    return response.data;
  }

  // Chats — rutas reales: backend/src/routes/chatRoutes.js
  async getChats() {
    const response = await this.client.get('/api/chat/conversations');
    return response.data;
  }

  async getMessages(partnerId: number | string) {
    const response = await this.client.get(`/api/chat/messages/${partnerId}`);
    return response.data;
  }

  async sendMessage(partnerId: number | string, data: SendMessagePayload) {
    const response = await this.client.post('/api/chat/messages', {
      receiver_id: partnerId,
      ...data,
    });
    return response.data;
  }

  // Profile — el backend expone PATCH /api/users/profile (backend/index.js), no PUT.
  async updateProfile(data: UpdateProfilePayload) {
    const response = await this.client.patch('/api/users/profile', data);
    return response.data;
  }
}

export const apiClient = new ApiClient();

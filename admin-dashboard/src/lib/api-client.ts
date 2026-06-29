import axios, { AxiosInstance, AxiosError } from 'axios';

// IMPORTANTE: Tu backend está en puerto 3000
const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

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
          localStorage.removeItem('glow_token');
          localStorage.removeItem('glow_user');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  // Bookings
  async getBookings(filters?: any) {
    const response = await this.client.get('/api/bookings', { params: filters });
    return response.data;
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

  // Chats
  async getChats() {
    const response = await this.client.get('/api/chats');
    return response.data;
  }

  async getMessages(chatId: number) {
    const response = await this.client.get(`/api/chats/${chatId}/messages`);
    return response.data;
  }

  async sendMessage(chatId: number, data: any) {
    const response = await this.client.post(`/api/chats/${chatId}/messages`, data);
    return response.data;
  }

  // Profile
  async updateProfile(data: any) {
    const response = await this.client.put('/api/users/profile', data);
    return response.data;
  }
}

export const apiClient = new ApiClient();

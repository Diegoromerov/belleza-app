'use client';

import { useState, useEffect } from 'react';
import { apiClient } from '../lib/api-client';
import { Booking } from '../types/booking';

export interface UseBookingsFilters {
  rol?: 'cliente' | 'prestador' | 'ADMIN';
  [key: string]: any;
}

export function useBookings(filters?: UseBookingsFilters) {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<any>(null);

  const fetchBookings = async () => {
    setLoading(true);
    try {
      const data = await apiClient.getBookings(filters);
      setBookings(data);
      setError(null);
    } catch (err) {
      setError(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBookings();
  }, [JSON.stringify(filters)]);

  const cancelBooking = async (id: number | string) => {
    try {
      await apiClient.cancelBooking(Number(id));
      // Refresh bookings
      await fetchBookings();
      return true;
    } catch (err) {
      setError(err);
      throw err;
    }
  };

  return {
    bookings,
    loading,
    error,
    refetch: fetchBookings,
    cancelBooking,
  };
}

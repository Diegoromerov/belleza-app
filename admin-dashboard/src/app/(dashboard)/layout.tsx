'use client';

import React, { useState } from 'react';
import ProtectedRoute from '@/components/auth/ProtectedRoute';
import Header from '@/components/dashboard/Header';
import Sidebar from '@/components/dashboard/Sidebar';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <ProtectedRoute allowedRoles={['ADMIN']}>
      <div className="dashboard-layout">
        <Sidebar />
        {/* Main Content */}
        <main className="main-content">
          <Header onMenuClick={() => setSidebarOpen(true)} />
          <div className="content-area">
            {children}
          </div>
        </main>
      </div>
    </ProtectedRoute>
  );
}

import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Navigation } from './components/Navigation';
import { DriverDashboard } from './pages/DriverDashboard';
import { DispatchDashboard } from './pages/DispatchDashboard';
import { DriverManagement } from './pages/DriverManagement';
import { ParLevels } from './pages/ParLevels';
import { StorePage } from './pages/StorePage';
import { ContainerLogs } from './pages/ContainerLogs';
import { Login } from './pages/Login';

function ProtectedRoutes() {
  const { user } = useAuth();

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navigation />
      <main className="container mx-auto px-4 py-8">
        <Routes>
          <Route path="/driver-dashboard" element={<DriverDashboard />} />
          <Route path="/dispatch-dashboard" element={<DispatchDashboard />} />
          <Route path="/driver-management" element={<DriverManagement />} />
          <Route path="/par-levels" element={<ParLevels />} />
          <Route path="/store" element={<StorePage />} />
          <Route path="/container-logs" element={<ContainerLogs />} />
          <Route path="/" element={<Navigate to="/driver-dashboard" replace />} />
        </Routes>
      </main>
    </div>
  );
}

function PublicRoute({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  
  if (user) {
    return <Navigate to="/driver-dashboard" replace />;
  }
  
  return <>{children}</>;
}

export function App() {
  return (
    <Router>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<PublicRoute><Login /></PublicRoute>} />
          <Route path="/*" element={<ProtectedRoutes />} />
        </Routes>
      </AuthProvider>
    </Router>
  );
}
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Truck, Users, LogOut, Ruler, Warehouse, ClipboardList, Menu, X, Mail } from 'lucide-react';
import { useState } from 'react';

const navItems = [
  {
    to: '/driver-dashboard',
    icon: Truck,
    label: 'Driver Dashboard'
  },
  {
    to: '/driver-management',
    icon: Users,
    label: 'Driver Management'
  },
  {
    to: '/dispatch-dashboard',
    icon: Users,
    label: 'Dispatch Dashboard'
  },
  {
    to: '/par-levels',
    icon: Ruler,
    label: 'Par Levels'
  },
  {
    to: '/store',
    icon: Warehouse,
    label: 'Store Entry'
  },
  {
    to: '/container-logs',
    icon: ClipboardList,
    label: 'Container Logs'
  }
];

export function Navigation() {
  const { user, signOut } = useAuth();
  const navigate = useNavigate();
  const [isOpen, setIsOpen] = useState(false);

  if (!user) return null;

  const handleLogout = async () => {
    try {
      await signOut();
      navigate('/login', { replace: true });
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  return (
    <div className="sticky top-0 z-50">
      {/* User Email Bar */}
      <div className="bg-gray-100 py-2">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-end gap-2 text-sm text-gray-600">
            <Mail className="h-4 w-4" />
            <span>{user.email}</span>
          </div>
        </div>
      </div>

      {/* Main Navigation */}
      <nav className="bg-white shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center space-x-8">
              {navItems.map((item) => (
                <Link
                  key={item.to}
                  to={item.to}
                  className="flex items-center space-x-2 text-gray-700 hover:text-blue-600"
                >
                  <item.icon className="h-5 w-5" />
                  <span>{item.label}</span>
                </Link>
              ))}
            </div>

            {/* Mobile Menu Button */}
            <div className="md:hidden flex items-center">
              <button
                onClick={() => setIsOpen(!isOpen)}
                className="text-gray-700 hover:text-blue-600"
              >
                {isOpen ? (
                  <X className="h-6 w-6" />
                ) : (
                  <Menu className="h-6 w-6" />
                )}
              </button>
            </div>

            {/* Logout Button */}
            <div className="flex items-center">
              <button
                onClick={handleLogout}
                className="flex items-center space-x-2 text-gray-700 hover:text-red-600"
              >
                <LogOut className="h-5 w-5" />
                <span>Logout</span>
              </button>
            </div>
          </div>

          {/* Mobile Navigation */}
          {isOpen && (
            <div className="md:hidden pb-4">
              <div className="flex flex-col space-y-4">
                {navItems.map((item) => (
                  <Link
                    key={item.to}
                    to={item.to}
                    className="flex items-center space-x-2 text-gray-700 hover:text-blue-600 px-2 py-1"
                    onClick={() => setIsOpen(false)}
                  >
                    <item.icon className="h-5 w-5" />
                    <span>{item.label}</span>
                  </Link>
                ))}
              </div>
            </div>
          )}
        </div>
      </nav>
    </div>
  );
}
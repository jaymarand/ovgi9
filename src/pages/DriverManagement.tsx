import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';

interface Driver {
  id: string;
  user_id: string;
  email: string;
  first_name: string;
  last_name: string;
  has_cdl: boolean;
  cdl_number: string | null;
  cdl_expiration_date: string | null;
  is_active: boolean;
  created_at: string;
}

interface NewDriver {
  email: string;
  first_name: string;
  last_name: string;
  has_cdl: boolean;
  cdl_number: string;
  cdl_expiration_date: string;
}

export function DriverManagement() {
  const { user } = useAuth();
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hideInactive, setHideInactive] = useState(false);
  const [showAddDriver, setShowAddDriver] = useState(false);
  const [showSetPassword, setShowSetPassword] = useState(false);
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [newDriver, setNewDriver] = useState<NewDriver>({
    email: '',
    first_name: '',
    last_name: '',
    has_cdl: false,
    cdl_number: '',
    cdl_expiration_date: '',
  });

  useEffect(() => {
    fetchDrivers();
  }, []);

  const fetchDrivers = async () => {
    try {
      setLoading(true);
      setError(null);

      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        throw new Error('Not authenticated');
      }

      const { data, error } = await supabase
        .from('drivers')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) {
        if (error.code === '42501') {
          throw new Error('You do not have permission to view drivers. Please contact your administrator.');
        }
        throw error;
      }

      setDrivers(data || []);
    } catch (err: any) {
      console.error('Error fetching drivers:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleAddDriver = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setLoading(true);
      setError(null);

      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        throw new Error('Not authenticated');
      }

      // Generate a temporary password
      const tempPassword = Math.random().toString(36).slice(-12) + Math.random().toString(36).slice(-12);

      // Call the server function to create the driver and auth user
      const { data, error: createError } = await supabase
        .rpc('create_driver_user', {
          p_email: newDriver.email.trim(),
          p_password: tempPassword,
          p_first_name: newDriver.first_name.trim(),
          p_last_name: newDriver.last_name.trim(),
          p_has_cdl: newDriver.has_cdl,
          p_cdl_number: newDriver.has_cdl ? newDriver.cdl_number.trim() : null,
          p_cdl_expiration_date: newDriver.has_cdl ? newDriver.cdl_expiration_date : null
        });

      if (createError) {
        throw new Error(createError.message);
      }

      // Show success message
      setError(`Driver created successfully. Please set their password immediately.`);
      
      setNewDriver({
        email: '',
        first_name: '',
        last_name: '',
        has_cdl: false,
        cdl_number: '',
        cdl_expiration_date: '',
      });
      setShowAddDriver(false);
      await fetchDrivers();

      // Automatically open set password modal for the new driver
      if (data && data.driver) {
        setSelectedDriver(data.driver);
        setShowSetPassword(true);
      }

    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteDriver = async (driverId: string) => {
    try {
      setLoading(true);
      setError(null);

      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        throw new Error('Not authenticated');
      }

      const userRole = session.user.user_metadata.role;
      if (userRole !== 'dispatcher') {
        throw new Error('Only dispatchers can delete drivers');
      }

      const { error: deleteError } = await supabase
        .from('drivers')
        .delete()
        .eq('id', driverId);

      if (deleteError) {
        if (deleteError.code === '42501') {
          throw new Error('You do not have permission to delete drivers. Please contact your administrator.');
        }
        throw new Error(deleteError.message);
      }

      await fetchDrivers();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleToggleStatus = async (driver: Driver) => {
    try {
      setLoading(true);
      setError(null);

      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        throw new Error('Not authenticated');
      }

      const userRole = session.user.user_metadata.role;
      if (userRole !== 'dispatcher') {
        throw new Error('Only dispatchers can modify driver status');
      }

      const { error: updateError } = await supabase
        .from('drivers')
        .update({ is_active: !driver.is_active })
        .eq('id', driver.id);

      if (updateError) {
        if (updateError.code === '42501') {
          throw new Error('You do not have permission to modify drivers. Please contact your administrator.');
        }
        throw new Error(updateError.message);
      }

      await fetchDrivers();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDriver) return;

    try {
      setLoading(true);
      setError(null);

      if (password !== confirmPassword) {
        throw new Error('Passwords do not match');
      }

      if (password.length < 8) {
        throw new Error('Password must be at least 8 characters long');
      }

      const { data: { session } } = await supabase.auth.getSession();
      if (!session) {
        throw new Error('Not authenticated');
      }

      // Call the server-side function to update the password
      const { data, error: updateError } = await supabase
        .rpc('update_user_password', {
          user_id: selectedDriver.user_id,
          new_password: password
        });

      if (updateError) {
        throw new Error(updateError.message);
      }

      setPassword('');
      setConfirmPassword('');
      setSelectedDriver(null);
      setShowSetPassword(false);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const filteredDrivers = hideInactive 
    ? drivers.filter(d => d.is_active)
    : drivers;

  if (loading && !showAddDriver) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading drivers...</div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-6">
        <div className="flex items-center space-x-4">
          <h1 className="text-2xl font-bold">Driver Management</h1>
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={hideInactive}
              onChange={(e) => setHideInactive(e.target.checked)}
              className="rounded border-gray-300 text-blue-600"
            />
            <span className="text-sm text-gray-700">Hide Inactive Drivers</span>
          </label>
        </div>
        <button
          onClick={() => setShowAddDriver(true)}
          className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
        >
          Add Driver
        </button>
      </div>

      {error && (
        <div className="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 mb-4" role="alert">
          <p>{error}</p>
        </div>
      )}

      {showAddDriver && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-bold">Add New Driver</h3>
              <button
                onClick={() => setShowAddDriver(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                ✕
              </button>
            </div>
            <form onSubmit={handleAddDriver} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Email</label>
                <input
                  type="email"
                  required
                  value={newDriver.email}
                  onChange={(e) => setNewDriver({ ...newDriver, email: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">First Name</label>
                <input
                  type="text"
                  required
                  value={newDriver.first_name}
                  onChange={(e) => setNewDriver({ ...newDriver, first_name: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Last Name</label>
                <input
                  type="text"
                  required
                  value={newDriver.last_name}
                  onChange={(e) => setNewDriver({ ...newDriver, last_name: e.target.value })}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="flex items-center">
                  <input
                    type="checkbox"
                    checked={newDriver.has_cdl}
                    onChange={(e) => setNewDriver({ ...newDriver, has_cdl: e.target.checked })}
                    className="rounded border-gray-300 text-blue-600"
                  />
                  <span className="ml-2 text-sm text-gray-700">Has CDL</span>
                </label>
              </div>
              {newDriver.has_cdl && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-700">CDL Number</label>
                    <input
                      type="text"
                      required
                      value={newDriver.cdl_number}
                      onChange={(e) => setNewDriver({ ...newDriver, cdl_number: e.target.value })}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700">CDL Expiration Date</label>
                    <input
                      type="date"
                      required
                      value={newDriver.cdl_expiration_date}
                      onChange={(e) => setNewDriver({ ...newDriver, cdl_expiration_date: e.target.value })}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                  </div>
                </>
              )}
              <div className="flex justify-end space-x-2 mt-4">
                <button
                  type="button"
                  onClick={() => setShowAddDriver(false)}
                  className="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 disabled:opacity-50"
                >
                  {loading ? 'Adding...' : 'Add Driver'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {showSetPassword && selectedDriver && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full">
          <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-bold">Set Password for {selectedDriver.first_name} {selectedDriver.last_name}</h3>
              <button
                onClick={() => {
                  setShowSetPassword(false);
                  setSelectedDriver(null);
                  setPassword('');
                  setConfirmPassword('');
                }}
                className="text-gray-500 hover:text-gray-700"
              >
                ✕
              </button>
            </div>
            <form onSubmit={handleSetPassword} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">New Password</label>
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  minLength={8}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Confirm Password</label>
                <input
                  type="password"
                  required
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  minLength={8}
                />
              </div>
              <div className="flex justify-end space-x-2 mt-4">
                <button
                  type="button"
                  onClick={() => {
                    setShowSetPassword(false);
                    setSelectedDriver(null);
                    setPassword('');
                    setConfirmPassword('');
                  }}
                  className="px-4 py-2 bg-gray-300 text-gray-700 rounded-md hover:bg-gray-400"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 disabled:opacity-50"
                >
                  {loading ? 'Setting Password...' : 'Set Password'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="bg-white shadow rounded-lg overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">CDL</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {filteredDrivers.map((driver) => (
              <tr key={driver.id} className={!driver.is_active ? 'bg-gray-50' : ''}>
                <td className="px-6 py-4 whitespace-nowrap">
                  {driver.first_name} {driver.last_name}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {driver.email}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <button
                    onClick={() => handleToggleStatus(driver)}
                    className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full cursor-pointer transition-colors duration-200 ${
                      driver.is_active 
                        ? 'bg-green-100 text-green-800 hover:bg-green-200' 
                        : 'bg-gray-100 text-gray-800 hover:bg-gray-200'
                    }`}
                  >
                    {driver.is_active ? 'Active' : 'Inactive'}
                  </button>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                    driver.has_cdl ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'
                  }`}>
                    {driver.has_cdl ? `CDL: ${driver.cdl_number}` : 'No CDL'}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                  <button className="text-indigo-600 hover:text-indigo-900 mr-4">
                    Edit
                  </button>
                  <button
                    onClick={() => {
                      setSelectedDriver(driver);
                      setShowSetPassword(true);
                    }}
                    className="text-blue-600 hover:text-blue-900 mr-4"
                  >
                    Set Password
                  </button>
                  <button 
                    onClick={() => handleDeleteDriver(driver.id)}
                    className="text-red-600 hover:text-red-900"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
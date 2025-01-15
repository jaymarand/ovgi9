import { useState, useEffect } from 'react';
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

interface DriverFormData {
  email: string;
  firstName: string;
  lastName: string;
  hasCDL: boolean;
  cdlNumber: string;
  cdlExpirationDate: string;
}

export function DriverManagement() {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [hideInactive, setHideInactive] = useState(false);
  const [editingDriver, setEditingDriver] = useState<Driver | null>(null);
  const [newDriver, setNewDriver] = useState<DriverFormData>({
    email: '',
    firstName: '',
    lastName: '',
    hasCDL: false,
    cdlNumber: '',
    cdlExpirationDate: ''
  });

  const validateEmail = (email: string): boolean => {
    const emailRegex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email);
  };

  const toProperCase = (str: string): string => {
    return str
      .toLowerCase()
      .split(' ')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ')
      .trim();
  };

  useEffect(() => {
    fetchDrivers();
  }, []);

  const fetchDrivers = async () => {
    try {
      setLoading(true);
      setError(null);

      const { data, error: fetchError } = await supabase
        .from('drivers')
        .select('*')
        .order('created_at', { ascending: false });

      if (fetchError) throw fetchError;

      setDrivers(data || []);
    } catch (err: any) {
      console.error('Error fetching drivers:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const toggleDriverStatus = async (driver: Driver) => {
    try {
      setLoading(true);
      setError(null);

      const { error: updateError } = await supabase
        .from('drivers')
        .update({ is_active: !driver.is_active })
        .eq('id', driver.id)
        .select()
        .single();

      if (updateError) throw updateError;

      setDrivers(drivers.map(d => d.id === driver.id ? { ...d, is_active: !d.is_active } : d));
    } catch (err: any) {
      console.error('Error updating driver status:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const updateDriverCDL = async (driver: Driver, hasCDL: boolean, cdlNumber?: string, cdlExpirationDate?: string) => {
    try {
      setLoading(true);
      setError(null);

      if (hasCDL) {
        if (!cdlNumber?.trim()) {
          throw new Error('CDL number is required when CDL is enabled');
        }
        if (!cdlExpirationDate?.trim()) {
          throw new Error('CDL expiration date is required when CDL is enabled');
        }

        const expirationDate = new Date(cdlExpirationDate);
        if (expirationDate <= new Date()) {
          throw new Error('CDL expiration date must be in the future');
        }
      }

      const updateData = {
        has_cdl: hasCDL,
        cdl_number: hasCDL ? cdlNumber : null,
        cdl_expiration_date: hasCDL ? cdlExpirationDate : null
      };

      const { error: updateError } = await supabase
        .from('drivers')
        .update(updateData)
        .eq('id', driver.id)
        .select()
        .single();

      if (updateError) throw updateError;

      setDrivers(drivers.map(d => d.id === driver.id ? { ...d, ...updateData } : d));
      setEditingDriver(null);
    } catch (err: any) {
      console.error('Error updating driver CDL:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const createDriver = async (formData: DriverFormData) => {
    try {
      setLoading(true);
      setError(null);

      const firstName = toProperCase(formData.firstName);
      const lastName = toProperCase(formData.lastName);

      if (!validateEmail(formData.email)) {
        throw new Error('Please enter a valid email address');
      }

      if (formData.hasCDL) {
        if (!formData.cdlNumber?.trim()) {
          throw new Error('CDL number is required when CDL is enabled');
        }
        if (!formData.cdlExpirationDate?.trim()) {
          throw new Error('CDL expiration date is required when CDL is enabled');
        }

        const expirationDate = new Date(formData.cdlExpirationDate);
        if (expirationDate <= new Date()) {
          throw new Error('CDL expiration date must be in the future');
        }
      }

      const { error: createError } = await supabase
        .from('drivers')
        .insert([
          {
            email: formData.email,
            first_name: firstName,
            last_name: lastName,
            has_cdl: formData.hasCDL,
            cdl_number: formData.hasCDL ? formData.cdlNumber : null,
            cdl_expiration_date: formData.hasCDL ? formData.cdlExpirationDate : null,
            is_active: true
          }
        ])
        .select()
        .single();

      if (createError) throw createError;

      setShowModal(false);
      await fetchDrivers();
    } catch (err: any) {
      console.error('Error creating driver:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleAddDriver = async (e: React.FormEvent) => {
    e.preventDefault();
    await createDriver(newDriver);
  };

  const resetForm = () => {
    setNewDriver({
      email: '',
      firstName: '',
      lastName: '',
      hasCDL: false,
      cdlNumber: '',
      cdlExpirationDate: ''
    });
    setError(null);
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Driver Management</h1>
        <div className="flex items-center gap-4">
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={hideInactive}
              onChange={(e) => setHideInactive(e.target.checked)}
              className="rounded border-gray-300 text-blue-600"
            />
            <span className="text-sm text-gray-700">Hide Inactive Drivers</span>
          </label>
          <button
            onClick={() => {
              setShowModal(true);
              resetForm();
            }}
            className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
          >
            Add Driver
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}

      {loading && !editingDriver ? (
        <div className="text-center py-4">Loading...</div>
      ) : (
        <div className="bg-white shadow-md rounded my-6">
          <table className="min-w-full table-auto">
            <thead>
              <tr className="bg-gray-200 text-gray-600 uppercase text-sm leading-normal">
                <th className="py-3 px-6 text-left">Name</th>
                <th className="py-3 px-6 text-left">Email</th>
                <th className="py-3 px-6 text-center">CDL Status</th>
                <th className="py-3 px-6 text-center">Status</th>
                <th className="py-3 px-6 text-center">Actions</th>
              </tr>
            </thead>
            <tbody className="text-gray-600 text-sm">
              {drivers
                .filter(driver => !hideInactive || driver.is_active)
                .map((driver) => (
                  <tr key={driver.id} className="border-b border-gray-200 hover:bg-gray-100">
                    <td className="py-3 px-6 text-left">
                      {driver.first_name} {driver.last_name}
                    </td>
                    <td className="py-3 px-6 text-left">{driver.email}</td>
                    <td className="py-3 px-6 text-center">
                      {editingDriver?.id === driver.id ? (
                        <div className="flex flex-col space-y-2">
                          <label className="flex items-center justify-center space-x-2">
                            <input
                              type="checkbox"
                              checked={editingDriver.has_cdl}
                              onChange={(e) => setEditingDriver({
                                ...editingDriver,
                                has_cdl: e.target.checked,
                                cdl_number: e.target.checked ? editingDriver.cdl_number : null,
                                cdl_expiration_date: e.target.checked ? editingDriver.cdl_expiration_date : null
                              })}
                              className="rounded border-gray-300 text-blue-600"
                            />
                            <span>Has CDL</span>
                          </label>
                          {editingDriver.has_cdl && (
                            <>
                              <input
                                type="text"
                                required={editingDriver.has_cdl}
                                placeholder="CDL Number"
                                value={editingDriver.cdl_number || ''}
                                onChange={(e) => setEditingDriver({
                                  ...editingDriver,
                                  cdl_number: e.target.value.trim()
                                })}
                                className="px-2 py-1 border rounded"
                              />
                              <input
                                type="date"
                                required={editingDriver.has_cdl}
                                min={new Date().toISOString().split('T')[0]}
                                value={editingDriver.cdl_expiration_date || ''}
                                onChange={(e) => setEditingDriver({
                                  ...editingDriver,
                                  cdl_expiration_date: e.target.value
                                })}
                                className="px-2 py-1 border rounded"
                              />
                              <div className="flex justify-center space-x-2">
                                <button
                                  onClick={() => updateDriverCDL(
                                    driver,
                                    editingDriver.has_cdl,
                                    editingDriver.cdl_number || undefined,
                                    editingDriver.cdl_expiration_date || undefined
                                  )}
                                  className="bg-green-500 text-white px-2 py-1 rounded text-xs"
                                >
                                  Save
                                </button>
                                <button
                                  onClick={() => setEditingDriver(null)}
                                  className="bg-gray-500 text-white px-2 py-1 rounded text-xs"
                                >
                                  Cancel
                                </button>
                              </div>
                            </>
                          )}
                        </div>
                      ) : (
                        <button
                          onClick={() => setEditingDriver(driver)}
                          className={`${
                            driver.has_cdl
                              ? 'bg-green-200 text-green-700'
                              : 'bg-gray-200 text-gray-700'
                          } py-1 px-3 rounded-full text-xs hover:opacity-75`}
                        >
                          {driver.has_cdl ? 'CDL' : 'No CDL'}
                        </button>
                      )}
                    </td>
                    <td className="py-3 px-6 text-center">
                      <button
                        onClick={() => toggleDriverStatus(driver)}
                        className={`${
                          driver.is_active
                            ? 'bg-green-200 text-green-700'
                            : 'bg-red-200 text-red-700'
                        } py-1 px-3 rounded-full text-xs hover:opacity-75`}
                      >
                        {driver.is_active ? 'Active' : 'Inactive'}
                      </button>
                    </td>
                    <td className="py-3 px-6 text-center">
                      <div className="flex justify-center items-center">
                        <button
                          onClick={() => setEditingDriver(driver)}
                          className="text-blue-500 hover:text-blue-700"
                        >
                          Edit
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      )}

      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-lg p-8 max-w-md w-full">
            <h2 className="text-xl font-bold mb-4">Add New Driver</h2>
            <form onSubmit={handleAddDriver}>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Email</label>
                  <input
                    type="email"
                    required
                    pattern="[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
                    title="Please enter a valid email address"
                    value={newDriver.email}
                    onChange={(e) => setNewDriver({ ...newDriver, email: e.target.value.toLowerCase().trim() })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">First Name</label>
                  <input
                    type="text"
                    required
                    value={newDriver.firstName}
                    onChange={(e) => setNewDriver({ ...newDriver, firstName: toProperCase(e.target.value) })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Last Name</label>
                  <input
                    type="text"
                    required
                    value={newDriver.lastName}
                    onChange={(e) => setNewDriver({ ...newDriver, lastName: toProperCase(e.target.value) })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={newDriver.hasCDL}
                      onChange={(e) => setNewDriver({ ...newDriver, hasCDL: e.target.checked })}
                      className="rounded border-gray-300 text-blue-600"
                    />
                    <span className="ml-2 text-sm text-gray-700">Has CDL</span>
                  </label>
                </div>
                {newDriver.hasCDL && (
                  <>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">CDL Number</label>
                      <input
                        type="text"
                        required
                        value={newDriver.cdlNumber}
                        onChange={(e) => setNewDriver({ ...newDriver, cdlNumber: e.target.value.trim() })}
                        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700">CDL Expiration Date</label>
                      <input
                        type="date"
                        required
                        min={new Date().toISOString().split('T')[0]}
                        value={newDriver.cdlExpirationDate}
                        onChange={(e) => setNewDriver({ ...newDriver, cdlExpirationDate: e.target.value })}
                        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                      />
                    </div>
                  </>
                )}
              </div>
              <div className="mt-6 flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => {
                    setShowModal(false);
                    resetForm();
                  }}
                  className="bg-gray-200 text-gray-700 px-4 py-2 rounded hover:bg-gray-300"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 disabled:opacity-50"
                >
                  {loading ? 'Creating...' : 'Create Driver'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
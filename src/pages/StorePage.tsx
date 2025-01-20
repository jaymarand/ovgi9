import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Warehouse, AlertCircle } from 'lucide-react';

interface Store {
  id: string;
  department_number: string;
  store_name: string;
}

interface ContainerCount {
  store_id: string;
  opener_name: string;
  arrival_time: string;
  donation_count: number;
  trailer_fullness: number;
  hardlines_raw: number;
  softlines_raw: number;
  canvases: number;
  sleeves: number;
  caps: number;
  totes: number;
}

export function StorePage() {
  const [stores, setStores] = useState<Store[]>([]);
  const [selectedStore, setSelectedStore] = useState<string>('');
  const [formData, setFormData] = useState<Partial<ContainerCount>>({
    opener_name: '',
    arrival_time: '',
    donation_count: '',
    trailer_fullness: '',
    hardlines_raw: '',
    softlines_raw: '',
    canvases: '',
    sleeves: '',
    caps: '',
    totes: ''
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    fetchStores();
  }, []);

  const fetchStores = async () => {
    try {
      const { data, error } = await supabase
        .from('stores')
        .select('id, department_number, store_name')
        .order('department_number');

      if (error) throw error;
      setStores(data || []);
    } catch (err) {
      console.error('Error fetching stores:', err);
      setError('Failed to fetch stores');
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedStore) {
      setError('Please select a store');
      return;
    }

    if (!formData.opener_name || !formData.arrival_time) {
      setError('Please fill in opener name and arrival time');
      return;
    }

    // Check if any supply counts are missing or empty
    const requiredFields = [
      'donation_count',
      'trailer_fullness',
      'hardlines_raw',
      'softlines_raw',
      'canvases',
      'sleeves',
      'caps',
      'totes'
    ];

    const missingFields = requiredFields.filter(field => 
      !formData[field as keyof ContainerCount]
    );

    if (missingFields.length > 0) {
      setError(`Please fill in all supply counts: ${missingFields.join(', ')}`);
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      // Convert time string to ISO format with current date
      const today = new Date();
      const [hours, minutes] = formData.arrival_time.split(':');
      const arrivalDate = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 
        parseInt(hours), parseInt(minutes));

      const store = stores.find(s => s.id === selectedStore);
      if (!store) throw new Error('Store not found');

      const submitData = {
        store_id: selectedStore,
        department_number: store.department_number,
        store_name: store.store_name,
        opener_name: formData.opener_name,
        arrival_time: arrivalDate.toISOString(),
        donation_count: parseInt(formData.donation_count as string) || 0,
        trailer_fullness: parseInt(formData.trailer_fullness as string) || 0,
        hardlines_raw: parseInt(formData.hardlines_raw as string) || 0,
        softlines_raw: parseInt(formData.softlines_raw as string) || 0,
        canvases: parseInt(formData.canvases as string) || 0,
        sleeves: parseInt(formData.sleeves as string) || 0,
        caps: parseInt(formData.caps as string) || 0,
        totes: parseInt(formData.totes as string) || 0
      };

      const { error: insertError } = await supabase
        .from('daily_container_counts')
        .insert(submitData);

      if (insertError) throw insertError;

      // Reset form
      setSelectedStore('');
      setFormData({
        opener_name: '',
        arrival_time: '',
        donation_count: '',
        trailer_fullness: '',
        hardlines_raw: '',
        softlines_raw: '',
        canvases: '',
        sleeves: '',
        caps: '',
        totes: ''
      });
      
      alert('Container counts submitted successfully');
    } catch (err) {
      console.error('Error submitting counts:', err);
      setError('Failed to submit container counts');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold flex items-center gap-2 mb-6">
        <Warehouse className="h-6 w-6" />
        Container Count Entry
      </h1>

      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
          <div className="flex items-center">
            <AlertCircle className="h-5 w-5 text-red-500 mr-2" />
            <p className="text-red-700">{error}</p>
          </div>
        </div>
      )}
      
      <form onSubmit={handleSubmit} className="space-y-6 bg-white shadow-md rounded-lg p-6">
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
          <div>
            <label htmlFor="store" className="block text-sm font-medium text-gray-700">
              Store *
            </label>
            <select
              id="store"
              value={selectedStore}
              onChange={(e) => setSelectedStore(e.target.value)}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            >
              <option value="">Select a store</option>
              {stores.map((store) => (
                <option key={store.id} value={store.id}>
                  {store.department_number} - {store.store_name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="opener_name" className="block text-sm font-medium text-gray-700">
              Opener Name *
            </label>
            <input
              type="text"
              id="opener_name"
              name="opener_name"
              value={formData.opener_name}
              onChange={handleInputChange}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="arrival_time" className="block text-sm font-medium text-gray-700">
              Arrival Time *
            </label>
            <input
              type="time"
              id="arrival_time"
              name="arrival_time"
              value={formData.arrival_time}
              onChange={handleInputChange}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="donation_count" className="block text-sm font-medium text-gray-700">
              Donation Count *
            </label>
            <input
              type="number"
              id="donation_count"
              name="donation_count"
              min="0"
              value={formData.donation_count}
              onChange={handleInputChange}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="trailer_fullness" className="block text-sm font-medium text-gray-700">
              Trailer Fullness (%) *
            </label>
            <input
              type="number"
              id="trailer_fullness"
              name="trailer_fullness"
              min="0"
              max="100"
              value={formData.trailer_fullness}
              onChange={handleInputChange}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="hardlines_raw" className="block text-sm font-medium text-gray-700">
              Hardlines Raw *
            </label>
            <input
              type="number"
              id="hardlines_raw"
              name="hardlines_raw"
              min="0"
              value={formData.hardlines_raw}
              onChange={handleInputChange}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="softlines_raw" className="block text-sm font-medium text-gray-700">
              Softlines Raw *
            </label>
            <input
              type="number"
              id="softlines_raw"
              name="softlines_raw"
              min="0"
              value={formData.softlines_raw}
              onChange={handleInputChange}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="canvases" className="block text-sm font-medium text-gray-700">
              Canvases *
            </label>
            <input
              type="number"
              id="canvases"
              name="canvases"
              min="0"
              value={formData.canvases}
              onChange={handleInputChange}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="sleeves" className="block text-sm font-medium text-gray-700">
              Sleeves *
            </label>
            <input
              type="number"
              id="sleeves"
              name="sleeves"
              min="0"
              value={formData.sleeves}
              onChange={handleInputChange}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="caps" className="block text-sm font-medium text-gray-700">
              Caps *
            </label>
            <input
              type="number"
              id="caps"
              name="caps"
              min="0"
              value={formData.caps}
              onChange={handleInputChange}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>

          <div>
            <label htmlFor="totes" className="block text-sm font-medium text-gray-700">
              Totes *
            </label>
            <input
              type="number"
              id="totes"
              name="totes"
              min="0"
              value={formData.totes}
              onChange={handleInputChange}
              className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              required
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={submitting}
          className={`w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white ${
            submitting
              ? 'bg-gray-400 cursor-not-allowed'
              : 'bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500'
          }`}
        >
          {submitting ? 'Submitting...' : 'Submit Counts'}
        </button>
      </form>
    </div>
  );
}
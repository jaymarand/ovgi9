import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { format } from 'date-fns';
import { ClipboardList, Download, AlertTriangle, Trash2, Truck } from 'lucide-react';

interface Store {
  id: string;
  department_number: string;
  store_name: string;
}

interface ContainerCount {
  id: string;
  store_id: string;
  department_number: string;
  store_name: string;
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
  created_at: string;
}

export function ContainerLogs() {
  const [containerCounts, setContainerCounts] = useState<ContainerCount[]>([]);
  const [missingStores, setMissingStores] = useState<Store[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showConfirmDialog, setShowConfirmDialog] = useState(false);

  const fetchContainerCounts = async () => {
    try {
      setError(null);
      
      // First get all stores
      const { data: allStores, error: storesError } = await supabase
        .from('stores')
        .select('*')
        .order('department_number');

      if (storesError) throw storesError;

      // Get today's container counts
      const startOfDay = new Date();
      startOfDay.setHours(0, 0, 0, 0);
      
      const endOfDay = new Date();
      endOfDay.setHours(23, 59, 59, 999);

      const { data: counts, error: countsError } = await supabase
        .from('daily_container_counts')
        .select('*')
        .gte('created_at', startOfDay.toISOString())
        .lte('created_at', endOfDay.toISOString());

      if (countsError) throw countsError;

      // Find stores that haven't submitted today
      const submittedDepartments = new Set((counts || []).map(count => count.department_number));
      const missing = (allStores || []).filter(store => !submittedDepartments.has(store.department_number));
      
      setContainerCounts(counts || []);
      setMissingStores(missing);
    } catch (err) {
      console.error('Error fetching container counts:', err);
      setError('Failed to fetch container counts. Please try refreshing the page.');
    } finally {
      setLoading(false);
    }
  };

  const clearSubmissions = async () => {
    try {
      setError(null);
      const startOfDay = new Date();
      startOfDay.setHours(0, 0, 0, 0);
      
      const endOfDay = new Date();
      endOfDay.setHours(23, 59, 59, 999);

      const { error: deleteError } = await supabase
        .from('daily_container_counts')
        .delete()
        .gte('created_at', startOfDay.toISOString())
        .lte('created_at', endOfDay.toISOString());

      if (deleteError) throw deleteError;

      await fetchContainerCounts();
      alert('All submissions for today have been cleared');
    } catch (err) {
      console.error('Error clearing submissions:', err);
      setError('Failed to clear submissions. Please try again.');
    } finally {
      setShowConfirmDialog(false);
    }
  };

  useEffect(() => {
    fetchContainerCounts();

    const subscription = supabase
      .channel('container_counts_changes')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'daily_container_counts'
        },
        () => {
          fetchContainerCounts();
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const downloadCSV = () => {
    const csvData = [
      // Header row
      ['Status', 'Store Number', 'Store Name', 'Opener Name', 'Arrival Time', 'Donation Count', 
       'Trailer Fullness', 'Hardlines Raw', 'Softlines Raw', 'Canvases', 'Sleeves', 'Caps', 
       'Totes', 'Time Submitted'],
      // Submitted stores
      ...containerCounts.map(count => [
        'Submitted',
        count.department_number,
        count.store_name,
        count.opener_name,
        format(new Date(count.arrival_time), 'HH:mm'),
        count.donation_count,
        `${count.trailer_fullness}%`,
        count.hardlines_raw,
        count.softlines_raw,
        count.canvases,
        count.sleeves,
        count.caps,
        count.totes,
        format(new Date(count.created_at), 'MM/dd/yyyy HH:mm:ss')
      ]),
      // Missing stores
      ...missingStores.map(store => [
        'Missing',
        store.department_number,
        store.store_name,
        '', '', '', '', '', '', '', '', '', '', ''
      ])
    ];

    const csvContent = csvData
      .map(row => row.map(cell => `"${cell ?? ''}"`).join(','))
      .join('\n');

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', `container-counts-${format(new Date(), 'yyyy-MM-dd')}.csv`);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="max-w-[95%] mx-auto py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
          <ClipboardList className="h-6 w-6" />
          Container Count Log
        </h1>
        <div className="flex gap-4">
          <button
            onClick={downloadCSV}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700"
          >
            <Download className="h-4 w-4 mr-2" />
            Export to CSV
          </button>
          <button
            onClick={() => setShowConfirmDialog(true)}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-red-600 hover:bg-red-700"
          >
            <Trash2 className="h-4 w-4 mr-2" />
            Clear All
          </button>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
          <div className="flex">
            <AlertTriangle className="h-5 w-5 text-red-500" />
            <div className="ml-3">
              <p className="text-sm text-red-700">{error}</p>
            </div>
          </div>
        </div>
      )}

      {showConfirmDialog && (
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 max-w-sm w-full">
            <h3 className="text-lg font-medium text-gray-900">Clear All Submissions</h3>
            <p className="mt-2 text-sm text-gray-500">
              Are you sure you want to clear all container count submissions for today? This action cannot be undone.
            </p>
            <div className="mt-4 flex justify-end space-x-4">
              <button
                onClick={() => setShowConfirmDialog(false)}
                className="inline-flex justify-center px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={clearSubmissions}
                className="inline-flex justify-center px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-md hover:bg-red-700"
              >
                Clear All
              </button>
            </div>
          </div>
        </div>
      )}

      {missingStores.length > 0 && (
        <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-6 rounded-r-md">
          <div className="flex">
            <AlertTriangle className="h-5 w-5 text-yellow-400" />
            <div className="ml-3 flex-1">
              <h3 className="text-sm font-medium text-yellow-800">
                Missing Submissions ({missingStores.length} stores)
              </h3>
              <div className="mt-2 space-y-2">
                {missingStores.map((store) => (
                  <div 
                    key={store.id}
                    className="flex items-center gap-2 text-sm text-yellow-700 bg-yellow-100 rounded-md px-3 py-1.5"
                  >
                    <Truck className="h-4 w-4 flex-shrink-0" />
                    <span>{store.department_number} - {store.store_name}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="bg-white shadow-md rounded-lg overflow-hidden mb-6">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Store</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Opener</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">TOA</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Hardlines</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Softlines</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Canvases</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sleeves</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Caps</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Totes</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Trailer %</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Donations</th>
                <th scope="col" className="px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Submitted</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {containerCounts.map((count) => (
                <tr key={count.id} className="hover:bg-gray-50">
                  <td className="px-3 py-2 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{count.department_number}</div>
                    <div className="text-xs text-gray-500">{count.store_name}</div>
                  </td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{count.opener_name}</td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                    {format(new Date(count.arrival_time), 'HH:mm')}
                  </td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{count.hardlines_raw}</td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{count.softlines_raw}</td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{count.canvases}</td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{count.sleeves}</td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{count.caps}</td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{count.totes}</td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{count.trailer_fullness}%</td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">{count.donation_count}</td>
                  <td className="px-3 py-2 whitespace-nowrap text-sm text-gray-500">
                    {format(new Date(count.created_at), 'HH:mm')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
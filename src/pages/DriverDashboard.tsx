import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { Truck, Package, AlertCircle } from 'lucide-react';

interface DeliveryRun {
  id: string;
  status: 'pending' | 'loading' | 'preloaded' | 'in_transit' | 'complete';
  store_id: string;
  store_name: string;
  department_number: string;
  start_time: string | null;
  depart_time: string | null;
  complete_time: string | null;
}

export function DriverDashboard() {
  const { user } = useAuth();
  const [runs, setRuns] = useState<DeliveryRun[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (user) {
      fetchRuns();
      setupRealtimeSubscription();
    }
  }, [user]);

  const setupRealtimeSubscription = () => {
    const channel = supabase
      .channel('table-db-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'active_delivery_runs' },
        () => {
          fetchRuns();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  };

  const fetchRuns = async () => {
    try {
      const { data, error: fetchError } = await supabase
        .from('active_delivery_runs')
        .select('*')
        .eq('driver', user?.id) // Changed from driver_id to driver
        .order('created_at', { ascending: true });

      if (fetchError) throw fetchError;
      setRuns(data || []);
    } catch (err) {
      console.error('Error fetching runs:', err);
      setError('Failed to fetch delivery runs');
    } finally {
      setLoading(false);
    }
  };

  const updateRunStatus = async (runId: string, newStatus: DeliveryRun['status']) => {
    try {
      const updateData: any = { status: newStatus };
      
      if (newStatus === 'loading') {
        updateData.start_time = new Date().toISOString();
      } else if (newStatus === 'in_transit') {
        updateData.depart_time = new Date().toISOString();
      } else if (newStatus === 'complete') {
        updateData.complete_time = new Date().toISOString();
      }

      const { error: updateError } = await supabase
        .from('active_delivery_runs')
        .update(updateData)
        .eq('id', runId);

      if (updateError) throw updateError;
      await fetchRuns();
    } catch (err) {
      console.error('Error updating run status:', err);
      setError('Failed to update run status');
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
    <div className="max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-6 flex items-center gap-2">
        <Truck className="h-6 w-6" />
        Driver Dashboard
      </h1>

      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
          <div className="flex items-center">
            <AlertCircle className="h-5 w-5 text-red-500 mr-2" />
            <p className="text-red-700">{error}</p>
          </div>
        </div>
      )}

      <div className="grid gap-6">
        {runs.map((run) => (
          <div
            key={run.id}
            className="bg-white rounded-lg shadow-md p-6 border border-gray-200"
          >
            <div className="flex justify-between items-start mb-4">
              <div>
                <h2 className="text-xl font-semibold">{run.store_name}</h2>
                <p className="text-gray-600">Store ID: {run.store_id}</p>
                <p className="text-gray-600">Department: {run.department_number}</p>
              </div>
              <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                run.status === 'complete' ? 'bg-green-100 text-green-800' :
                run.status === 'in_transit' ? 'bg-blue-100 text-blue-800' :
                run.status === 'loading' ? 'bg-yellow-100 text-yellow-800' :
                'bg-gray-100 text-gray-800'
              }`}>
                {run.status.replace('_', ' ').charAt(0).toUpperCase() + run.status.slice(1)}
              </span>
            </div>

            <div className="flex gap-2 mt-4">
              {run.status === 'pending' && (
                <button
                  onClick={() => updateRunStatus(run.id, 'loading')}
                  className="bg-blue-500 text-white px-4 py-2 rounded-md hover:bg-blue-600 flex items-center gap-2"
                >
                  <Package className="h-4 w-4" />
                  Start Loading
                </button>
              )}
              {run.status === 'loading' && (
                <button
                  onClick={() => updateRunStatus(run.id, 'preloaded')}
                  className="bg-yellow-500 text-white px-4 py-2 rounded-md hover:bg-yellow-600"
                >
                  Mark as Preloaded
                </button>
              )}
              {run.status === 'preloaded' && (
                <button
                  onClick={() => updateRunStatus(run.id, 'in_transit')}
                  className="bg-blue-500 text-white px-4 py-2 rounded-md hover:bg-blue-600"
                >
                  Start Delivery
                </button>
              )}
              {run.status === 'in_transit' && (
                <button
                  onClick={() => updateRunStatus(run.id, 'complete')}
                  className="bg-green-500 text-white px-4 py-2 rounded-md hover:bg-green-600"
                >
                  Complete Delivery
                </button>
              )}
            </div>
          </div>
        ))}

        {runs.length === 0 && (
          <div className="bg-gray-50 rounded-lg p-8 text-center">
            <Package className="h-12 w-12 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No Active Runs</h3>
            <p className="text-gray-600">You currently have no active delivery runs assigned.</p>
          </div>
        )}
      </div>
    </div>
  );
}
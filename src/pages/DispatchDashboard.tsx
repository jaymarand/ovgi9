import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { Users, Truck, Package, AlertCircle, Plus } from 'lucide-react';

interface DeliveryRun {
  id: string;
  driver: string;
  store_id: string;
  store_name: string;
  department_number: string;
  status: 'pending' | 'loading' | 'preloaded' | 'in_transit' | 'complete' | 'cancelled';
  type: 'Box Truck' | 'Tractor Trailer';
  sleeves: number;
  caps: number;
  canvases: number;
  totes: number;
  hardlines_raw: number;
  softlines_raw: number;
  fl_driver: string;
  start_time: string | null;
  preload_time: string | null;
  complete_time: string | null;
  depart_time: string | null;
}

type RunType = 'All Runs' | 'Box Truck Runs' | 'Tractor Trailer Runs';
type RunTime = 'Morning Runs' | 'Afternoon Runs' | 'ADC Runs';

export function DispatchDashboard() {
  const { user } = useAuth();
  const [runs, setRuns] = useState<DeliveryRun[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedType, setSelectedType] = useState<RunType>('All Runs');

  useEffect(() => {
    fetchRuns();
    setupRealtimeSubscription();
  }, []);

  const setupRealtimeSubscription = () => {
    const channel = supabase
      .channel('dispatch-changes')
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
      const { data, error: runsError } = await supabase
        .from('active_delivery_runs')
        .select('*')
        .order('created_at', { ascending: false });

      if (runsError) throw runsError;
      setRuns(data || []);
    } catch (err) {
      setError('Failed to fetch delivery runs');
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: DeliveryRun['status']) => {
    switch (status) {
      case 'complete':
        return 'text-green-600 bg-green-50';
      case 'cancelled':
        return 'text-red-600 bg-red-50';
      case 'preloaded':
        return 'text-yellow-600 bg-yellow-50';
      case 'in_transit':
        return 'text-blue-600 bg-blue-50';
      default:
        return 'text-gray-600 bg-gray-50';
    }
  };

  const formatTime = (time: string | null) => {
    if (!time) return '--:--';
    return new Date(time).toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    });
  };

  const filterRunsByType = (runs: DeliveryRun[]) => {
    if (selectedType === 'All Runs') return runs;
    return runs.filter(run => run.type === selectedType.replace(' Runs', ''));
  };

  const groupRunsByTime = (runs: DeliveryRun[]): Record<RunTime, DeliveryRun[]> => {
    const morning = runs.filter(run => {
      const startHour = run.start_time ? new Date(run.start_time).getHours() : 0;
      return startHour >= 4 && startHour < 12;
    });
    const afternoon = runs.filter(run => {
      const startHour = run.start_time ? new Date(run.start_time).getHours() : 0;
      return startHour >= 12 && startHour < 20;
    });
    const adc = runs.filter(run => {
      const startHour = run.start_time ? new Date(run.start_time).getHours() : 0;
      return startHour >= 20 || startHour < 4;
    });

    return {
      'Morning Runs': morning,
      'Afternoon Runs': afternoon,
      'ADC Runs': adc
    };
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  const filteredRuns = filterRunsByType(runs);
  const groupedRuns = groupRunsByTime(filteredRuns);

  return (
    <div className="max-w-[95%] mx-auto">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Dispatch Dashboard</h1>
        <div className="flex gap-2">
          {(['All Runs', 'Box Truck Runs', 'Tractor Trailer Runs'] as RunType[]).map((type) => (
            <button
              key={type}
              onClick={() => setSelectedType(type)}
              className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${
                selectedType === type
                  ? 'bg-blue-500 text-white'
                  : 'bg-white text-gray-700 hover:bg-gray-50'
              }`}
            >
              {type}
            </button>
          ))}
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
          <div className="flex items-center">
            <AlertCircle className="h-5 w-5 text-red-500 mr-2" />
            <p className="text-red-700">{error}</p>
          </div>
        </div>
      )}

      {Object.entries(groupedRuns).map(([timeSlot, runs]) => (
        <div key={timeSlot} className="mb-8">
          <h2 className="text-xl font-semibold mb-4">{timeSlot}</h2>
          <div className="bg-white rounded-lg shadow-md overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Retail Store</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Sleeves</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Caps</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Canvases</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Totes</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Hardlines Raw</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Softlines Raw</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">FL Driver</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Start</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Preload</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Complete</th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Depart</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {runs.map((run) => (
                    <tr key={run.id} className="hover:bg-gray-50">
                      <td className="px-4 py-3 text-sm text-gray-900">{run.store_name}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">
                        <div className="flex items-center">
                          <Truck className="h-4 w-4 mr-1" />
                          {run.type}
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(run.status)}`}>
                          {run.status.charAt(0).toUpperCase() + run.status.slice(1)}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-900">{run.sleeves}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{run.caps}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{run.canvases}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{run.totes}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{run.hardlines_raw}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{run.softlines_raw}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">{run.fl_driver || '--'}</td>
                      <td className="px-4 py-3 text-sm text-blue-600">{formatTime(run.start_time)}</td>
                      <td className="px-4 py-3 text-sm text-blue-600">{formatTime(run.preload_time)}</td>
                      <td className="px-4 py-3 text-sm text-blue-600">{formatTime(run.complete_time)}</td>
                      <td className="px-4 py-3 text-sm text-blue-600">{formatTime(run.depart_time)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="p-4 border-t border-gray-200">
              <button className="flex items-center justify-center w-full py-2 text-sm text-blue-600 hover:bg-blue-50 rounded-md">
                <Plus className="h-4 w-4 mr-1" />
                Add Run
              </button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
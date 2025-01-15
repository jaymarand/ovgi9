import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { Users, Truck, Package, AlertCircle, Plus, ChevronDown } from 'lucide-react';

interface Store {
  id: string;
  store_name: string;
  department_number: string;
}

interface Driver {
  id: string;
  name: string;
}

interface DeliveryRun {
  run_id: string;
  store_name: string;
  department_number: string;
  run_type: string;
  type: string;
  status: string;
  position: number;
  fl_driver_id: string | null;
  start_time: string | null;
  preload_time: string | null;
  complete_time: string | null;
  depart_time: string | null;
  created_at: string;
  updated_at: string;
  sleeves_needed: number;
  caps_needed: number;
  canvases_needed: number;
  totes_needed: number;
  hardlines_needed: number;
  softlines_needed: number;
}

type RunType = 'All Runs' | 'Box Truck Runs' | 'Tractor Trailer Runs';
type RunTime = 'Morning Runs' | 'Afternoon Runs' | 'ADC Runs';

const timeSlotToRunType = (timeSlot: string): string => {
  switch (timeSlot) {
    case 'Morning Runs':
      return 'morning_runs';
    case 'Afternoon Runs':
      return 'afternoon_runs';
    case 'ADC Runs':
      return 'adc_runs';
    default:
      return 'morning_runs';
  }
};

const runTypeToTimeSlot = (runType: string): string => {
  switch (runType) {
    case 'morning_runs':
      return 'Morning Runs';
    case 'afternoon_runs':
      return 'Afternoon Runs';
    case 'adc_runs':
      return 'ADC Runs';
    default:
      return 'Morning Runs';
  }
};

export function DispatchDashboard() {
  const { user } = useAuth();
  const [runs, setRuns] = useState<DeliveryRun[]>([]);
  const [stores, setStores] = useState<Store[]>([]);
  const [activeDrivers, setActiveDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedType, setSelectedType] = useState<RunType>('All Runs');
  const [showStoreDropdown, setShowStoreDropdown] = useState<string | null>(null); // timeSlot when dropdown is open

  useEffect(() => {
    fetchRuns();
    fetchStores();
    fetchActiveDrivers();
    setupRealtimeSubscription();
  }, []);

  const setupRealtimeSubscription = () => {
    const channel = supabase
      .channel('dispatch-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'active_delivery_runs' },
        (payload) => {
          console.log('Realtime update received:', payload);
          fetchRuns();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  };

  const fetchStores = async () => {
    try {
      const { data, error: storesError } = await supabase
        .from('stores')
        .select('*')
        .order('store_name');

      if (storesError) throw storesError;
      setStores(data || []);
    } catch (err) {
      setError('Failed to fetch stores');
    }
  };

  const fetchRuns = async () => {
    try {
      console.log('Fetching runs...');
      const { data, error: runsError } = await supabase
        .from('run_supply_needs')
        .select('*')
        .neq('status', 'cancelled')
        .order('created_at', { ascending: false });

      if (runsError) throw runsError;
      console.log('Fetched runs:', data);
      setRuns(data || []);
    } catch (err) {
      console.error('Failed to fetch delivery runs:', err);
      setError('Failed to fetch delivery runs');
    } finally {
      setLoading(false);
    }
  };

  const fetchActiveDrivers = async () => {
    try {
      const { data, error: driversError } = await supabase
        .from('drivers')
        .select('id, first_name, last_name')
        .eq('is_active', true)
        .order('first_name');

      if (driversError) throw driversError;
      setActiveDrivers(data?.map(d => ({
        id: d.id,
        name: `${d.first_name} ${d.last_name}`
      })) || []);
    } catch (err) {
      console.error('Failed to fetch drivers:', err);
      setError('Failed to fetch drivers');
    }
  };

  const addRun = async (store: Store, timeSlot: string) => {
    try {
      const runType = timeSlotToRunType(timeSlot);
      
      const { data, error: addError } = await supabase.rpc('add_delivery_run', {
        p_run_type: runType.split('_')[0], // Convert 'morning_runs' to 'morning'
        p_store_id: store.id,
        p_store_name: store.store_name,
        p_department_number: store.department_number,
        p_truck_type: 'box_truck'
      });

      if (addError) {
        console.error('Add run error:', addError);
        throw addError;
      }
      setShowStoreDropdown(null);
      await fetchRuns();
    } catch (err) {
      console.error('Failed to add run:', err);
      setError('Failed to add run');
    }
  };

  const updateVehicleType = async (runId: string, newType: string) => {
    try {
      console.log('Updating run:', runId, 'to type:', newType);
      const { error: updateError } = await supabase
        .from('active_delivery_runs')
        .update({ truck_type: newType })
        .eq('id', runId);

      if (updateError) {
        console.error('Update error:', updateError);
        throw updateError;
      }
      
      // Force refresh the data
      const { data: updatedData, error: refreshError } = await supabase
        .from('run_supply_needs')
        .select('*')
        .eq('run_id', runId)
        .single();

      if (refreshError) {
        console.error('Refresh error:', refreshError);
      } else if (updatedData) {
        // Update the local state immediately
        setRuns(prev => prev.map(run => 
          run.run_id === runId ? { ...run, type: updatedData.type } : run
        ));
      }
    } catch (err) {
      console.error('Failed to update vehicle type:', err);
      setError('Failed to update vehicle type');
    }
  };

  const handleDriverAssignment = async (runId: string, driverId: string | null) => {
    try {
      // Optimistically update the UI
      setRuns(prevRuns => prevRuns.map(run => 
        run.run_id === runId ? { ...run, fl_driver_id: driverId } : run
      ));

      const { error: assignError } = await supabase
        .rpc('assign_driver_to_run', {
          p_run_id: runId,
          p_driver_id: driverId
        });

      if (assignError) throw assignError;

      // Fetch the updated run to ensure we have the latest data
      const { data: updatedRun, error: fetchError } = await supabase
        .from('run_supply_needs')
        .select('*')
        .eq('run_id', runId)
        .single();

      if (fetchError) throw fetchError;

      // Update the specific run with the latest data
      if (updatedRun) {
        setRuns(prevRuns => prevRuns.map(run => 
          run.run_id === runId ? { ...run, ...updatedRun } : run
        ));
      }
    } catch (err) {
      console.error('Error assigning driver:', err);
      setError('Failed to assign driver');
      // Revert the optimistic update on error
      await fetchRuns();
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
    return {
      'Morning Runs': runs.filter(run => run.run_type === 'morning_runs'),
      'Afternoon Runs': runs.filter(run => run.run_type === 'afternoon_runs'),
      'ADC Runs': runs.filter(run => run.run_type === 'adc_runs')
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

      {Object.entries(groupedRuns).map(([timeSlot, runsInSlot]) => (
        <div key={`section-${timeSlot}`} className="mb-8">
          <div className="bg-white rounded-lg shadow-md overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Retail Store</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Type</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Status</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Sleeves</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Caps</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Canvases</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Totes</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Hardlines Raw</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Softlines Raw</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">FL Driver</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Start</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Preload</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Complete</th>
                    <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Depart</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  <tr key={`header-${timeSlot}`} className="bg-gray-50">
                    <td colSpan={14} className="px-4 py-2">
                      <div className="flex justify-between items-center">
                        <span className="font-medium text-gray-900">{timeSlot}</span>
                        <button
                          onClick={() => setShowStoreDropdown(showStoreDropdown === timeSlot ? null : timeSlot)}
                          className="inline-flex items-center px-3 py-1 border border-transparent text-sm leading-4 font-medium rounded-md text-blue-600 bg-blue-100 hover:bg-blue-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                        >
                          <Plus className="h-4 w-4 mr-1" />
                          Add Run
                        </button>
                      </div>
                      {showStoreDropdown === timeSlot && (
                        <div className="mt-2 relative">
                          <select
                            onChange={(e) => {
                              const store = stores.find(s => s.id === e.target.value);
                              if (store) addRun(store, timeSlot);
                            }}
                            className="block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm rounded-md"
                            defaultValue=""
                          >
                            <option value="" disabled>Select a store...</option>
                            {stores.map((store) => (
                              <option key={store.id} value={store.id}>
                                {store.store_name} ({store.department_number})
                              </option>
                            ))}
                          </select>
                        </div>
                      )}
                    </td>
                  </tr>
                  {runsInSlot.map((run) => (
                    <tr key={`run-${run.run_id || run.id}`} className="hover:bg-gray-50">
                      <td className="px-4 py-3 text-sm text-gray-900">{run.store_name}</td>
                      <td className="px-4 py-3 text-sm text-gray-900">
                        <div className="flex items-center justify-center">
                          <Truck className="h-4 w-4 mr-1" />
                          <select
                            value={run.type || 'box_truck'}
                            onChange={(e) => updateVehicleType(run.run_id, e.target.value)}
                            className="block w-36 text-sm border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 rounded-md"
                          >
                            <option value="box_truck">Box Truck</option>
                            <option value="tractor_trailer">Tractor Trailer</option>
                          </select>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-center">
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${getStatusColor(run.status)}`}>
                          {run.status.charAt(0).toUpperCase() + run.status.slice(1).replace('_', ' ')}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">{run.sleeves_needed}</td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">{run.caps_needed}</td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">{run.canvases_needed}</td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">{run.totes_needed}</td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">{run.hardlines_needed}</td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">{run.softlines_needed}</td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">
                        <select
                          value={run.fl_driver_id || ''}
                          onChange={(e) => handleDriverAssignment(run.run_id, e.target.value || null)}
                          className="block w-40 text-sm border-gray-300 focus:outline-none focus:ring-blue-500 focus:border-blue-500 rounded-md"
                        >
                          <option value="">Select Driver</option>
                          {activeDrivers.map((driver) => (
                            <option key={driver.id} value={driver.id}>
                              {driver.name}
                            </option>
                          ))}
                        </select>
                      </td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">{formatTime(run.start_time)}</td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">{formatTime(run.preload_time)}</td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">{formatTime(run.complete_time)}</td>
                      <td className="px-4 py-3 text-sm text-center text-gray-900">{formatTime(run.depart_time)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
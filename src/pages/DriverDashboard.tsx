import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import { Truck, Package, AlertCircle, Loader, RotateCcw } from 'lucide-react';

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

interface DeliveryRun {
  run_id: string;
  store_name: string;
  department_number: string;
  status: 'upcoming' | 'loading' | 'preloaded' | 'in_transit' | 'complete';
  fl_driver_id: string;
  start_time: string | null;
  preload_time: string | null;
  depart_time: string | null;
  complete_time: string | null;
  sleeves_needed: number;
  caps_needed: number;
  canvases_needed: number;
  totes_needed: number;
  hardlines_needed: number;
  softlines_needed: number;
}

interface SupplyEntry {
  sleeves: number;
  caps: number;
  canvases: number;
  totes: number;
  hardlines: number;
  softlines: number;
}

export function DriverDashboard() {
  const { user } = useAuth();
  const [selectedDriver, setSelectedDriver] = useState<string>('');
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [runs, setRuns] = useState<DeliveryRun[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [supplies, setSupplies] = useState<SupplyEntry>({
    sleeves: 0,
    caps: 0,
    canvases: 0,
    totes: 0,
    hardlines: 0,
    softlines: 0
  });
  const [selectedRun, setSelectedRun] = useState<DeliveryRun | null>(null);

  useEffect(() => {
    fetchDrivers();
    setupRealtimeSubscription();
  }, []);

  useEffect(() => {
    if (selectedDriver) {
      fetchRuns();
    }
  }, [selectedDriver]);

  const fetchDrivers = async () => {
    try {
      const { data, error: driversError } = await supabase
        .from('drivers')
        .select('*')
        .eq('is_active', true)
        .order('last_name', { ascending: true });

      if (driversError) throw driversError;
      console.log('Fetched drivers:', data);
      setDrivers(data || []);
    } catch (err) {
      console.error('Error fetching drivers:', err);
      setError('Failed to fetch drivers');
    } finally {
      setLoading(false);
    }
  };

  const setupRealtimeSubscription = () => {
    const channel = supabase
      .channel('driver-dashboard-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'active_delivery_runs' },
        () => {
          if (selectedDriver) fetchRuns();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  };

  const fetchRuns = async () => {
    if (!selectedDriver) return;
    
    try {
      setLoading(true);
      console.log('Fetching runs for driver:', selectedDriver);
      const { data, error: runsError } = await supabase
        .from('run_supply_needs')
        .select(`
          run_id,
          store_name,
          department_number,
          status,
          fl_driver_id,
          start_time,
          preload_time,
          depart_time,
          complete_time,
          sleeves_needed,
          caps_needed,
          canvases_needed,
          totes_needed,
          hardlines_needed,
          softlines_needed,
          created_at
        `)
        .eq('fl_driver_id', selectedDriver)
        .neq('status', 'complete')
        .order('created_at');

      if (runsError) {
        console.error('Error fetching runs:', runsError);
        throw runsError;
      }
      console.log('Fetched runs:', data);
      
      // Transform the data to match our interface
      const transformedRuns = data?.map(run => ({
        run_id: run.run_id,
        store_name: run.store_name,
        department_number: run.department_number,
        status: run.status,
        fl_driver_id: run.fl_driver_id,
        start_time: run.start_time,
        preload_time: run.preload_time,
        depart_time: run.depart_time,
        complete_time: run.complete_time,
        sleeves_needed: run.sleeves_needed || 0,
        caps_needed: run.caps_needed || 0,
        canvases_needed: run.canvases_needed || 0,
        totes_needed: run.totes_needed || 0,
        hardlines_needed: run.hardlines_needed || 0,
        softlines_needed: run.softlines_needed || 0
      })) || [];

      console.log('Transformed runs:', transformedRuns);
      setRuns(transformedRuns);
    } catch (err) {
      console.error('Error fetching runs:', err);
      setError('Failed to fetch delivery runs');
    } finally {
      setLoading(false);
    }
  };

  const updateRunStatus = async (runId: string, newStatus: DeliveryRun['status']) => {
    try {
      console.log('Updating run status:', { runId, newStatus });
      const currentTime = new Date().toISOString();
      const updateData: any = {
        status: newStatus,
        updated_at: currentTime
      };

      // Add appropriate timestamp based on status
      switch (newStatus) {
        case 'loading':
          updateData.start_time = currentTime;
          break;
        case 'preloaded':
          updateData.preload_time = currentTime;
          // Create supply exception when stopping loading
          const run = runs.find(r => r.run_id === runId);
          if (run) {
            console.log('Creating supply exception for run:', run);
            const { error: supplyError } = await supabase
              .from('supply_exceptions')
              .insert({
                run_id: runId,
                requested_sleeves: run.sleeves_needed,
                requested_caps: run.caps_needed,
                requested_canvases: run.canvases_needed,
                requested_totes: run.totes_needed,
                requested_hardlines: run.hardlines_needed,
                requested_softlines: run.softlines_needed,
                actual_sleeves: supplies.sleeves,
                actual_caps: supplies.caps,
                actual_canvases: supplies.canvases,
                actual_totes: supplies.totes,
                actual_hardlines: supplies.hardlines,
                actual_softlines: supplies.softlines,
                created_at: currentTime
              });
            
            if (supplyError) {
              console.error('Error creating supply exception:', supplyError);
              throw supplyError;
            }
          }
          break;
        case 'in_transit':
          updateData.depart_time = currentTime;
          break;
        case 'complete':
          updateData.complete_time = currentTime;
          break;
      }

      console.log('Updating run with data:', updateData);
      const { error: updateError } = await supabase
        .from('active_delivery_runs')
        .update(updateData)
        .eq('id', runId);

      if (updateError) {
        console.error('Error updating run:', updateError);
        throw updateError;
      }

      await fetchRuns();
    } catch (err) {
      console.error('Error updating run status:', err);
      setError('Failed to update run status');
    }
  };

  const resetRun = async (runId: string) => {
    try {
      console.log('Resetting run:', runId);
      const currentTime = new Date().toISOString();
      const updateData = {
        status: 'upcoming',
        updated_at: currentTime,
        start_time: null,
        preload_time: null,
        depart_time: null,
        complete_time: null
      };

      const { error: updateError } = await supabase
        .from('active_delivery_runs')
        .update(updateData)
        .eq('id', runId);

      if (updateError) {
        console.error('Error resetting run:', updateError);
        throw updateError;
      }

      await fetchRuns();
    } catch (err) {
      console.error('Error resetting run:', err);
      setError('Failed to reset run');
    }
  };

  const getStatusColor = (status: DeliveryRun['status']) => {
    switch (status) {
      case 'complete':
        return 'bg-green-100 text-green-800';
      case 'in_transit':
        return 'bg-blue-100 text-blue-800';
      case 'preloaded':
        return 'bg-yellow-100 text-yellow-800';
      case 'loading':
        return 'bg-orange-100 text-orange-800';
      case 'upcoming':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const handleRunClick = (run: DeliveryRun) => {
    console.log('Run clicked:', run);
    setSelectedRun(run);
    setSupplies({
      sleeves: 0,
      caps: 0,
      canvases: 0,
      totes: 0,
      hardlines: 0,
      softlines: 0
    });
  };

  const getActionButton = (run: DeliveryRun) => {
    console.log('Getting action button for run:', run);
    console.log('Selected run:', selectedRun);

    const resetButton = (
      <button
        onClick={(e) => {
          e.stopPropagation();
          resetRun(run.run_id);
        }}
        className="bg-gray-500 text-white px-4 py-2 rounded-md hover:bg-gray-600 flex items-center gap-2"
      >
        <RotateCcw className="h-4 w-4" />
        Reset
      </button>
    );

    switch (run.status) {
      case 'upcoming':
        return (
          <div className="flex flex-wrap gap-2 mt-4">
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateRunStatus(run.run_id, 'loading');
              }}
              className="bg-blue-500 text-white px-4 py-2 rounded-md hover:bg-blue-600 flex items-center gap-2"
            >
              <Package className="h-4 w-4" />
              Start Loading
            </button>
            {resetButton}
          </div>
        );
      case 'loading':
        return (
          <div className="flex flex-wrap gap-2 mt-4">
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateRunStatus(run.run_id, 'preloaded');
              }}
              className="bg-yellow-500 text-white px-4 py-2 rounded-md hover:bg-yellow-600 flex items-center gap-2"
            >
              <Loader className="h-4 w-4" />
              Stop Loading
            </button>
            {resetButton}
          </div>
        );
      case 'preloaded':
        return (
          <div className="flex flex-wrap gap-2 mt-4">
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateRunStatus(run.run_id, 'in_transit');
              }}
              className="bg-blue-500 text-white px-4 py-2 rounded-md hover:bg-blue-600"
            >
              Depart
            </button>
            {resetButton}
          </div>
        );
      case 'in_transit':
        return (
          <div className="flex flex-wrap gap-2 mt-4">
            <button
              onClick={(e) => {
                e.stopPropagation();
                updateRunStatus(run.run_id, 'complete');
              }}
              className="bg-green-500 text-white px-4 py-2 rounded-md hover:bg-green-600"
            >
              Complete
            </button>
            {resetButton}
          </div>
        );
      case 'complete':
        return (
          <div className="flex flex-wrap gap-2 mt-4">
            {resetButton}
          </div>
        );
      default:
        return null;
    }
  };

  const handleSupplyChange = (field: keyof SupplyEntry, value: number) => {
    setSupplies(prev => ({
      ...prev,
      [field]: value
    }));
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto px-4 py-6">
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

      <div className="mb-6">
        <label htmlFor="driver-select" className="block text-sm font-medium text-gray-700 mb-2">
          Select Driver
        </label>
        <select
          id="driver-select"
          value={selectedDriver}
          onChange={(e) => {
            setSelectedDriver(e.target.value);
            setSelectedRun(null); // Reset selected run when driver changes
          }}
          className="block w-full md:w-64 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        >
          <option value="">Select a driver</option>
          {drivers.map((driver) => (
            <option key={driver.id} value={driver.id}>
              {driver.first_name} {driver.last_name}
            </option>
          ))}
        </select>
      </div>

      <div className="grid gap-6">
        {runs.map((run) => (
          <div
            key={run.run_id}
            onClick={() => handleRunClick(run)}
            className={`bg-white rounded-lg shadow-md p-6 border transition-all cursor-pointer hover:shadow-lg ${
              selectedRun?.run_id === run.run_id 
                ? 'border-blue-500 ring-2 ring-blue-500 ring-opacity-50' 
                : 'border-gray-200 hover:border-blue-300'
            }`}
          >
            <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-4">
              <div>
                <h2 className="text-xl font-semibold">{run.store_name}</h2>
                <p className="text-gray-600">Department: {run.department_number}</p>
              </div>
              <span className={`mt-2 md:mt-0 px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(run.status)}`}>
                {run.status.replace('_', ' ').charAt(0).toUpperCase() + run.status.slice(1)}
              </span>
            </div>

            {selectedRun?.run_id === run.run_id && run.status === 'loading' && (
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-4 p-4 bg-gray-50 rounded-lg" onClick={e => e.stopPropagation()}>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Sleeves</label>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      min="0"
                      value={supplies.sleeves}
                      onChange={(e) => handleSupplyChange('sleeves', parseInt(e.target.value) || 0)}
                      className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-500">/ {run.sleeves_needed}</span>
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Caps</label>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      min="0"
                      value={supplies.caps}
                      onChange={(e) => handleSupplyChange('caps', parseInt(e.target.value) || 0)}
                      className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-500">/ {run.caps_needed}</span>
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Canvases</label>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      min="0"
                      value={supplies.canvases}
                      onChange={(e) => handleSupplyChange('canvases', parseInt(e.target.value) || 0)}
                      className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-500">/ {run.canvases_needed}</span>
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Totes</label>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      min="0"
                      value={supplies.totes}
                      onChange={(e) => handleSupplyChange('totes', parseInt(e.target.value) || 0)}
                      className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-500">/ {run.totes_needed}</span>
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Hardlines</label>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      min="0"
                      value={supplies.hardlines}
                      onChange={(e) => handleSupplyChange('hardlines', parseInt(e.target.value) || 0)}
                      className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-500">/ {run.hardlines_needed}</span>
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Softlines</label>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      min="0"
                      value={supplies.softlines}
                      onChange={(e) => handleSupplyChange('softlines', parseInt(e.target.value) || 0)}
                      className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                    <span className="text-sm text-gray-500">/ {run.softlines_needed}</span>
                  </div>
                </div>
              </div>
            )}

            {selectedRun?.run_id === run.run_id && getActionButton(run)}
          </div>
        ))}

        {runs.length === 0 && (
          <div className="bg-gray-50 rounded-lg p-8 text-center">
            <Package className="h-12 w-12 mx-auto text-gray-400 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No Active Runs</h3>
            <p className="text-gray-600">
              {selectedDriver 
                ? "You currently have no active delivery runs assigned."
                : "Please select a driver to view their runs."}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
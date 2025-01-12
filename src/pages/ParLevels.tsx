import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { Ruler, AlertCircle, Save, Undo } from 'lucide-react';

interface StoreSupply {
  id: string;
  department_number: string;
  store_name: string;
  sleeves: number;
  caps: number;
  canvases: number;
  totes: number;
  hardlines_raw: number;
  softlines_raw: number;
}

type EditableField = 'sleeves' | 'caps' | 'canvases' | 'totes' | 'hardlines_raw' | 'softlines_raw';

interface EditState {
  storeId: string;
  field: EditableField;
  value: string;
  originalValue: number;
}

export function ParLevels() {
  const [supplies, setSupplies] = useState<StoreSupply[]>([]);
  const [editState, setEditState] = useState<EditState | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saveStatus, setSaveStatus] = useState<{storeId: string, status: 'saving' | 'success' | 'error'} | null>(null);

  useEffect(() => {
    fetchSupplies();
    setupRealtimeSubscription();
  }, []);

  const setupRealtimeSubscription = () => {
    const channel = supabase
      .channel('store-supplies-changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'store_supplies' },
        () => {
          fetchSupplies();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  };

  const fetchSupplies = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('store_supplies')
        .select('*')
        .order('department_number');

      if (error) throw error;
      setSupplies(data || []);
    } catch (err: any) {
      console.error('Error fetching supplies:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (supply: StoreSupply, field: EditableField) => {
    setEditState({
      storeId: supply.id,
      field,
      value: supply[field].toString(),
      originalValue: supply[field]
    });
  };

  const handleCancel = () => {
    setEditState(null);
  };

  const handleUpdate = async (supply: StoreSupply) => {
    if (!editState) return;
    
    try {
      setSaveStatus({ storeId: supply.id, status: 'saving' });
      const value = parseInt(editState.value);
      
      if (isNaN(value) || value < 0) {
        throw new Error('Please enter a valid positive number');
      }

      const { error } = await supabase
        .from('store_supplies')
        .update({ [editState.field]: value })
        .eq('id', supply.id);

      if (error) throw error;
      
      setSaveStatus({ storeId: supply.id, status: 'success' });
      setTimeout(() => setSaveStatus(null), 2000);
      setEditState(null);
    } catch (err: any) {
      console.error('Error updating supply:', err);
      setSaveStatus({ storeId: supply.id, status: 'error' });
      setTimeout(() => setSaveStatus(null), 3000);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  const fields: { key: EditableField; label: string }[] = [
    { key: 'sleeves', label: 'Sleeves' },
    { key: 'caps', label: 'Caps' },
    { key: 'canvases', label: 'Canvases' },
    { key: 'totes', label: 'Totes' },
    { key: 'hardlines_raw', label: 'Hardlines Raw' },
    { key: 'softlines_raw', label: 'Softlines Raw' }
  ];

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <Ruler className="h-6 w-6" />
          Store Par Levels
        </h1>
      </div>

      {error && (
        <div className="bg-red-50 border-l-4 border-red-500 p-4 mb-6">
          <div className="flex items-center">
            <AlertCircle className="h-5 w-5 text-red-500 mr-2" />
            <p className="text-red-700">{error}</p>
          </div>
        </div>
      )}

      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Store
                </th>
                {fields.map(field => (
                  <th key={field.key} className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    {field.label}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {supplies.map((supply) => (
                <tr key={supply.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{supply.department_number}</div>
                    <div className="text-xs text-gray-500">{supply.store_name}</div>
                  </td>
                  {fields.map(({ key }) => (
                    <td key={key} className="px-6 py-4 whitespace-nowrap">
                      {editState?.storeId === supply.id && editState?.field === key ? (
                        <div className="flex items-center gap-2">
                          <input
                            type="number"
                            value={editState.value}
                            onChange={(e) => setEditState({ ...editState, value: e.target.value })}
                            onKeyPress={(e) => {
                              if (e.key === 'Enter') {
                                handleUpdate(supply);
                              }
                            }}
                            className="w-20 px-2 py-1 border rounded-md focus:ring-blue-500 focus:border-blue-500"
                            min="0"
                            autoFocus
                          />
                          <button
                            onClick={() => handleUpdate(supply)}
                            className="p-1 text-green-600 hover:text-green-800"
                            title="Save"
                          >
                            <Save className="h-4 w-4" />
                          </button>
                          <button
                            onClick={handleCancel}
                            className="p-1 text-gray-600 hover:text-gray-800"
                            title="Cancel"
                          >
                            <Undo className="h-4 w-4" />
                          </button>
                        </div>
                      ) : (
                        <div
                          onClick={() => handleEdit(supply, key)}
                          className={`cursor-pointer hover:bg-blue-50 px-3 py-1 rounded transition-colors ${
                            saveStatus?.storeId === supply.id
                              ? saveStatus.status === 'saving'
                                ? 'text-gray-400'
                                : saveStatus.status === 'success'
                                ? 'text-green-600'
                                : 'text-red-600'
                              : 'text-gray-900'
                          }`}
                        >
                          {supply[key]}
                        </div>
                      )}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
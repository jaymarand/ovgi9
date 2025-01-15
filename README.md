# OVGI Dispatch Dashboard

A modern web application for managing delivery runs and store supplies efficiently.

## Features

- **Real-time Dispatch Dashboard**: View and manage delivery runs in real-time
- **Store Management**: Add and manage store information and supply needs
- **Run Types**: Support for Morning, Afternoon, and ADC runs
- **Supply Tracking**: Track various supplies including sleeves, caps, canvases, totes, and more
- **Status Management**: Track run status from pending through completion
- **Driver Assignment**: Assign and track drivers for each run

## Tech Stack

- **Frontend**: React with TypeScript
- **Backend**: Supabase (PostgreSQL)
- **Authentication**: Supabase Auth
- **Styling**: Tailwind CSS
- **Icons**: Lucide React

## Database Schema

### Tables
- `stores`: Store information and department numbers
- `active_delivery_runs`: Active delivery runs and their status
- `store_supplies`: Store supply par levels
- `daily_container_counts`: Daily supply counts for each store

### Views
- `run_supply_needs`: Calculated supply needs for each run

### Functions
- `add_delivery_run`: Creates a new delivery run
- Various driver management functions

### Enums
- `run_type`: Morning, Afternoon, ADC
- `vehicle_type`: Box Truck, Tractor Trailer
- `delivery_status`: Pending, Loading, Preloaded, In Transit, Complete, Cancelled

## Recent Updates

### 2025-01-14
- Added inline store selection dropdown
- Implemented run creation directly from dashboard
- Added supply needs calculation and display
- Fixed case-sensitivity issues with run types
- Added proper error handling and logging

## Setup Instructions

1. Clone the repository
2. Install dependencies: `npm install`
3. Set up Supabase project and update credentials
4. Run migrations in the `supabase/migrations` folder
5. Start development server: `npm run dev`

## Security

- Row Level Security (RLS) policies implemented for all tables
- Authentication required for all database operations
- Secure function execution with appropriate permissions

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - See LICENSE file for details
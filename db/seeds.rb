# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command.

# --- Clear existing data ---
puts "Destroying existing records..."
TimeOffRequest.destroy_all
User.destroy_all
Department.destroy_all
TimeOffType.destroy_all

# --- Create Departments ---
puts "Creating Departments..."
engineering = Department.create!(name: 'Engineering')
sales = Department.create!(name: 'Sales')
hr = Department.create!(name: 'Human Resources')

# --- Create Time Off Types ---
puts "Creating Time Off Types..."
vacation = TimeOffType.create!(name: 'Vacation')
sick_leave = TimeOffType.create!(name: 'Sick Leave')
personal_day = TimeOffType.create!(name: 'Personal Day')

# --- Create Users ---
puts "Creating Users..."

# Top-level Admin
admin_user = User.create!(
  name: 'Admin User',
  email: 'admin@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :admin,
  department: hr,
  manager: nil # Admin has no manager
)

# Manager who reports to the Admin
manager_user = User.create!(
  name: 'Manager User',
  email: 'manager@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :manager,
  department: engineering,
  manager: admin_user
)

# Employee 1 who reports to the Manager
User.create!(
  name: 'Mauricio Barros',
  email: 'mauricio.barros@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :employee,
  department: engineering,
  manager: manager_user
)

# Employee 2 who reports to the Manager
employee2 = User.create!(
  name: 'Jane Smith',
  email: 'jane.smith@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :employee,
  department: sales,
  manager: admin_user # Let's have this one report to the admin for variety
)

# --- Create a sample Time Off Request ---
puts "Creating a sample Time Off Request..."
TimeOffRequest.create!(
  user: employee2,
  time_off_type: vacation,
  start_date: Date.today + 10.days,
  end_date: Date.today + 15.days,
  reason: 'Family vacation to Hawaii.',
  status: :pending
)

puts "Seeding finished!"
puts "Created #{Department.count} departments."
puts "Created #{TimeOffType.count} time off types."
puts "Created #{User.count} users."
puts "Created #{TimeOffRequest.count} time off requests."
# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command.

# --- Clear existing data ---
puts "Destroying existing records..."
TimeOffRequest.destroy_all
User.destroy_all
Department.destroy_all
TimeOffType.destroy_all
Approval.destroy_all

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

# Managers who reports to the Admin
manager_user = User.create!(
  name: 'Manager User',
  email: 'manager@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :manager,
  department: engineering,
  manager: admin_user
)

manager_user2 = User.create!(
  name: 'Manager User 2',
  email: 'manager2@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :manager,
  department: sales,
  manager: admin_user
)

# Employee 1 who reports to the Manager
employee = User.create!(
  name: 'Mauricio Barros',
  email: 'mauricio.barros@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :employee,
  department: engineering,
  manager: manager_user
)

# Employee 2 who reports to the Admin
employee2 = User.create!(
  name: 'Jane Smith',
  email: 'jane.smith@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :employee,
  department: sales,
  manager: admin_user # Let's have this one report to the admin for variety
)

# Employee 3 who reports to the Manager 2
employee3 = User.create!(
  name: 'John Doe',
  email: 'john.doe@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :employee,
  department: sales,
  manager: manager_user2
)

# --- Create some sample Time Off Requests ---
puts "Creating some sample Time Off Requests..."
TimeOffRequest.create!(
  user: employee2,
  time_off_type: vacation,
  start_date: Date.today + 10.days,
  end_date: Date.today + 15.days,
  reason: 'Family vacation to Hawaii.',
  status: :pending
)

TimeOffRequest.create!(
  user: employee3,
  time_off_type: sick_leave,
  start_date: Date.today + 20.days,
  end_date: Date.today + 25.days,
  reason: 'Sick leave due to flu.',
  status: :pending
)

TimeOffRequest.create!(
  user: employee,
  time_off_type: personal_day,
  start_date: Date.today + 30.days,
  end_date: Date.today + 35.days,
  reason: 'Personal day off.',
  status: :pending
)

TimeOffRequest.create!(
  user: employee3,
  time_off_type: vacation,
  start_date: Date.today + 40.days,
  end_date: Date.today + 45.days,
  reason: 'Vacation to Europe.',
  status: :pending
)

TimeOffRequest.create!(
  user: employee,
  time_off_type: personal_day,
  start_date: Date.today + 50.days,
  end_date: Date.today + 55.days,
  reason: 'Personal day off.',
  status: :pending
)

TimeOffRequest.create!(
  user: employee2,
  time_off_type: sick_leave,
  start_date: Date.today + 60.days,
  end_date: Date.today + 65.days,
  reason: 'Surgery',
  status: :pending
)

puts "Seeding finished!"
puts "Created #{Department.count} departments."
puts "Created #{TimeOffType.count} time off types."
puts "Created #{User.count} users."
puts "Created #{TimeOffRequest.count} time off requests."

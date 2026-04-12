# Seed data for CUHK Venue & Equipment Booking System
# Run with: bin/rails db:seed

puts "Seeding database..."

# === Tenants ===
cs_dept = Tenant.find_or_create_by!(name: "Computer Science") do |t|
  t.description = "Department of Computer Science and Engineering"
  t.is_active = true
  t.cancellation_deadline_hours = 24
  t.point_deduction_per_late_cancel = 10
  t.max_recurring_days = 180
end

ee_dept = Tenant.find_or_create_by!(name: "Electronic Engineering") do |t|
  t.description = "Department of Electronic Engineering"
  t.is_active = true
  t.cancellation_deadline_hours = 12
  t.point_deduction_per_late_cancel = 15
  t.max_recurring_days = 90
end

math_dept = Tenant.find_or_create_by!(name: "Mathematics") do |t|
  t.description = "Department of Mathematics"
  t.is_active = true
  t.cancellation_deadline_hours = 48
  t.point_deduction_per_late_cancel = 5
  t.max_recurring_days = 120
end

# === Admin User ===
admin = User.find_or_initialize_by(email: "admin@cuhk.edu.hk")
admin.assign_attributes(
  username: "admin",
  full_name: "System Administrator",
  role: :admin,
  tenant: cs_dept,
  is_active: true,
  points: 999
)
admin.password = "admin123"
admin.save!

# === CS Department Users ===
cs_admin = User.find_or_initialize_by(email: "cs_admin@cuhk.edu.hk")
cs_admin.assign_attributes(
  username: "cs_admin",
  full_name: "CS Department Admin",
  role: :tenant_admin,
  tenant: cs_dept,
  is_active: true,
  points: 100
)
cs_admin.password = "password123"
cs_admin.save!

alice = User.find_or_initialize_by(email: "alice@cuhk.edu.hk")
alice.assign_attributes(
  username: "alice",
  full_name: "Alice Wong",
  role: :user,
  tenant: cs_dept,
  is_active: true,
  points: 100
)
alice.password = "password123"
alice.save!

bob = User.find_or_initialize_by(email: "bob@cuhk.edu.hk")
bob.assign_attributes(
  username: "bob",
  full_name: "Bob Chan",
  role: :user,
  tenant: cs_dept,
  is_active: true,
  points: 80
)
bob.password = "password123"
bob.save!

# === EE Department Users ===
ee_admin = User.find_or_initialize_by(email: "ee_admin@cuhk.edu.hk")
ee_admin.assign_attributes(
  username: "ee_admin",
  full_name: "EE Department Admin",
  role: :tenant_admin,
  tenant: ee_dept,
  is_active: true,
  points: 100
)
ee_admin.password = "password123"
ee_admin.save!

charlie = User.find_or_initialize_by(email: "charlie@cuhk.edu.hk")
charlie.assign_attributes(
  username: "charlie",
  full_name: "Charlie Lee",
  role: :user,
  tenant: ee_dept,
  is_active: true,
  points: 90
)
charlie.password = "password123"
charlie.save!

# === Venues ===
lt1 = Venue.find_or_create_by!(tenant: cs_dept, name: "Lecture Theatre 1") do |v|
  v.description = "Large lecture theatre with projector and sound system"
  v.capacity = 200
  v.location = "Ho Sin Hang Engineering Building"
  v.latitude = 22.4196
  v.longitude = 114.2068
  v.features = { "projector" => true, "wifi" => true, "air_conditioning" => true, "microphone" => true }
  v.available_from = "08:00"
  v.available_until = "22:00"
  v.is_active = true
end

seminar_room = Venue.find_or_create_by!(tenant: cs_dept, name: "Seminar Room 101") do |v|
  v.description = "Small seminar room for group discussions"
  v.capacity = 30
  v.location = "Ho Sin Hang Engineering Building, 1/F"
  v.latitude = 22.4197
  v.longitude = 114.2069
  v.features = { "projector" => true, "wifi" => true, "whiteboard" => true }
  v.available_from = "09:00"
  v.available_until = "21:00"
  v.is_active = true
end

cs_lab = Venue.find_or_create_by!(tenant: cs_dept, name: "Computer Lab 3") do |v|
  v.description = "Computer lab with 60 workstations"
  v.capacity = 60
  v.location = "Ho Sin Hang Engineering Building, 3/F"
  v.latitude = 22.4198
  v.longitude = 114.2070
  v.features = { "computers" => true, "wifi" => true, "projector" => true }
  v.available_from = "08:00"
  v.available_until = "20:00"
  v.is_active = true
end

ee_lab = Venue.find_or_create_by!(tenant: ee_dept, name: "EE Lab A") do |v|
  v.description = "Electronics lab with oscilloscopes and testing equipment"
  v.capacity = 40
  v.location = "Science Centre East Block"
  v.latitude = 22.4200
  v.longitude = 114.2065
  v.features = { "oscilloscopes" => true, "power_supplies" => true, "wifi" => true }
  v.available_from = "09:00"
  v.available_until = "18:00"
  v.is_active = true
end

ee_room = Venue.find_or_create_by!(tenant: ee_dept, name: "EE Meeting Room") do |v|
  v.description = "Meeting room for department gatherings"
  v.capacity = 20
  v.location = "Science Centre East Block, 2/F"
  v.latitude = 22.4201
  v.longitude = 114.2066
  v.features = { "projector" => true, "whiteboard" => true, "video_conference" => true }
  v.available_from = "08:00"
  v.available_until = "22:00"
  v.is_active = true
end

# === Equipment ===
Equipment.find_or_create_by!(tenant: cs_dept, name: "HD Projector") do |e|
  e.description = "Epson HD projector with HDMI"
  e.quantity = 3
  e.equipment_type = "AV"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: cs_dept, name: "Wireless Microphone Set") do |e|
  e.description = "Shure wireless microphone with receiver"
  e.quantity = 2
  e.equipment_type = "audio"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: cs_dept, name: "Portable Speaker") do |e|
  e.description = "JBL portable Bluetooth speaker"
  e.quantity = 4
  e.equipment_type = "audio"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: cs_dept, name: "Laptop") do |e|
  e.description = "Dell Latitude for presentations"
  e.quantity = 5
  e.equipment_type = "computer"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: ee_dept, name: "Oscilloscope") do |e|
  e.description = "Tektronix digital oscilloscope"
  e.quantity = 10
  e.equipment_type = "lab"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: ee_dept, name: "Signal Generator") do |e|
  e.description = "Keysight function/signal generator"
  e.quantity = 8
  e.equipment_type = "lab"
  e.status = "available"
  e.is_active = true
end

# === Sample Bookings ===
Booking.find_or_create_by!(user: alice, venue: lt1, title: "CSCI3100 Group Meeting") do |b|
  b.description = "Weekly project sync for Group 5"
  b.start_time = 2.days.from_now.change(hour: 14)
  b.end_time = 2.days.from_now.change(hour: 16)
  b.status = :confirmed
  b.contact_person = "Alice Wong"
  b.contact_email = "alice@cuhk.edu.hk"
  b.contact_phone = "91234567"
  b.estimated_attendance = 5
end

Booking.find_or_create_by!(user: bob, venue: seminar_room, title: "Study Group Session") do |b|
  b.description = "Exam preparation study group"
  b.start_time = 3.days.from_now.change(hour: 10)
  b.end_time = 3.days.from_now.change(hour: 12)
  b.status = :pending
  b.contact_person = "Bob Chan"
  b.contact_email = "bob@cuhk.edu.hk"
  b.contact_phone = "98765432"
  b.estimated_attendance = 15
end

Booking.find_or_create_by!(user: charlie, venue: ee_lab, title: "Lab Practice") do |b|
  b.description = "Circuit design lab practice"
  b.start_time = 1.day.from_now.change(hour: 14)
  b.end_time = 1.day.from_now.change(hour: 17)
  b.status = :confirmed
  b.contact_person = "Charlie Lee"
  b.contact_email = "charlie@cuhk.edu.hk"
  b.contact_phone = "96543210"
  b.estimated_attendance = 20
end

puts "Seeding complete!"
puts "  Tenants: #{Tenant.count}"
puts "  Users: #{User.count}"
puts "  Venues: #{Venue.count}"
puts "  Equipment: #{Equipment.count}"
puts "  Bookings: #{Booking.count}"
puts ""
puts "  Admin login: admin@cuhk.edu.hk / admin123"
puts "  User login:  alice@cuhk.edu.hk / password123"

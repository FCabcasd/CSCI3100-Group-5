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

phys_dept = Tenant.find_or_create_by!(name: "Physics") do |t|
  t.description = "Department of Physics"
  t.is_active = true
  t.cancellation_deadline_hours = 24
  t.point_deduction_per_late_cancel = 10
  t.max_recurring_days = 120
end

osa = Tenant.find_or_create_by!(name: "Office of Student Affairs") do |t|
  t.description = "Office of Student Affairs — manages common student activity venues"
  t.is_active = true
  t.cancellation_deadline_hours = 48
  t.point_deduction_per_late_cancel = 20
  t.max_recurring_days = 90
end

lib = Tenant.find_or_create_by!(name: "University Library") do |t|
  t.description = "CUHK University Library System"
  t.is_active = true
  t.cancellation_deadline_hours = 6
  t.point_deduction_per_late_cancel = 5
  t.max_recurring_days = 30
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

diana = User.find_or_initialize_by(email: "diana@cuhk.edu.hk")
diana.assign_attributes(
  username: "diana",
  full_name: "Diana Cheung",
  role: :user,
  tenant: cs_dept,
  is_active: true,
  points: 95
)
diana.password = "password123"
diana.save!

# === Physics Department Users ===
phys_admin = User.find_or_initialize_by(email: "phys_admin@cuhk.edu.hk")
phys_admin.assign_attributes(
  username: "phys_admin",
  full_name: "Physics Department Admin",
  role: :tenant_admin,
  tenant: phys_dept,
  is_active: true,
  points: 100
)
phys_admin.password = "password123"
phys_admin.save!

evan = User.find_or_initialize_by(email: "evan@cuhk.edu.hk")
evan.assign_attributes(
  username: "evan",
  full_name: "Evan Lau",
  role: :user,
  tenant: phys_dept,
  is_active: true,
  points: 85
)
evan.password = "password123"
evan.save!

# === OSA Users ===
osa_admin = User.find_or_initialize_by(email: "osa_admin@cuhk.edu.hk")
osa_admin.assign_attributes(
  username: "osa_admin",
  full_name: "OSA Admin",
  role: :tenant_admin,
  tenant: osa,
  is_active: true,
  points: 100
)
osa_admin.password = "password123"
osa_admin.save!

# === Library Users ===
lib_admin = User.find_or_initialize_by(email: "lib_admin@cuhk.edu.hk")
lib_admin.assign_attributes(
  username: "lib_admin",
  full_name: "Library Admin",
  role: :tenant_admin,
  tenant: lib,
  is_active: true,
  points: 100
)
lib_admin.password = "password123"
lib_admin.save!

frank = User.find_or_initialize_by(email: "frank@cuhk.edu.hk")
frank.assign_attributes(
  username: "frank",
  full_name: "Frank Ng",
  role: :user,
  tenant: lib,
  is_active: true,
  points: 75
)
frank.password = "password123"
frank.save!

# === Venues ===
# Real CUHK buildings with accurate GPS coordinates

# -- CS Department (Ho Sin-Hang Engineering Building, 何善衡工程学大楼) --
lt1 = Venue.find_or_create_by!(tenant: cs_dept, name: "ERB LT") do |v|
  v.description = "Large lecture theatre with tiered seating, dual projectors, and surround sound"
  v.capacity = 200
  v.location = "Ho Sin-Hang Engineering Building, G/F, CUHK"
  v.latitude = 22.418331107993925
  v.longitude = 114.20733769843808
  v.features = { "projector" => true, "wifi" => true, "air_conditioning" => true, "microphone" => true, "recording" => true }
  v.available_from = "08:00"
  v.available_until = "22:00"
  v.is_active = true
end

seminar_room = Venue.find_or_create_by!(tenant: cs_dept, name: "ERB 407") do |v|
  v.description = "Seminar room for group discussions and presentations"
  v.capacity = 30
  v.location = "Ho Sin-Hang Engineering Building, 4/F, Room 407"
  v.latitude = 22.418331107993925
  v.longitude = 114.20733769843808
  v.features = { "projector" => true, "wifi" => true, "whiteboard" => true }
  v.available_from = "09:00"
  v.available_until = "21:00"
  v.is_active = true
end

cs_lab = Venue.find_or_create_by!(tenant: cs_dept, name: "SHB 924") do |v|
  v.description = "Computer lab with 60 workstations running Linux/Windows dual-boot"
  v.capacity = 60
  v.location = "Sino Building (SHB), 9/F, Room 924, CUHK"
  v.latitude = 22.415680888737672
  v.longitude = 114.20746433282476
  v.features = { "computers" => true, "wifi" => true, "projector" => true, "printing" => true }
  v.available_from = "08:00"
  v.available_until = "20:00"
  v.is_active = true
end

yia_room = Venue.find_or_create_by!(tenant: cs_dept, name: "YIA 404") do |v|
  v.description = "Tutorial room with flexible seating, smart board"
  v.capacity = 45
  v.location = "Yasumoto International Academic Park (YIA), 4/F, Room 404"
  v.latitude = 22.416549150912164
  v.longitude = 114.21108875425931
  v.features = { "smart_board" => true, "wifi" => true, "air_conditioning" => true, "flexible_seating" => true }
  v.available_from = "08:30"
  v.available_until = "21:30"
  v.is_active = true
end

# -- EE Department (Science Centre, 科学馆) --
ee_lab = Venue.find_or_create_by!(tenant: ee_dept, name: "SC L1") do |v|
  v.description = "Electronics teaching lab with oscilloscopes, power supplies, and soldering stations"
  v.capacity = 40
  v.location = "Science Centre East Block, 1/F, Lab L1, CUHK"
  v.latitude = 22.41938266631056
  v.longitude = 114.20871060823004
  v.features = { "oscilloscopes" => true, "power_supplies" => true, "wifi" => true, "soldering" => true }
  v.available_from = "09:00"
  v.available_until = "18:00"
  v.is_active = true
end

ee_room = Venue.find_or_create_by!(tenant: ee_dept, name: "SC 201") do |v|
  v.description = "Meeting room with video conferencing and whiteboard wall"
  v.capacity = 20
  v.location = "Science Centre East Block, 2/F, Room 201, CUHK"
  v.latitude = 22.41938266631056
  v.longitude = 114.20871060823004
  v.features = { "projector" => true, "whiteboard" => true, "video_conference" => true }
  v.available_from = "08:00"
  v.available_until = "22:00"
  v.is_active = true
end

wmw_lt = Venue.find_or_create_by!(tenant: ee_dept, name: "MMW 710") do |v|
  v.description = "Lecture room with stadium seating and AV system"
  v.capacity = 120
  v.location = "William M.W. Mong Engineering Building, 7/F, Room 710, CUHK"
  v.latitude = 22.418384621459598
  v.longitude = 114.20832529049633
  v.features = { "projector" => true, "microphone" => true, "wifi" => true, "air_conditioning" => true, "recording" => true }
  v.available_from = "08:00"
  v.available_until = "21:00"
  v.is_active = true
end

# -- Math Department (Lady Shaw Building, 邵逸夫夫人楼) --
lsb_lt = Venue.find_or_create_by!(tenant: math_dept, name: "LSB LT2") do |v|
  v.description = "Lecture theatre with chalkboards and projector"
  v.capacity = 150
  v.location = "Lady Shaw Building (LSB), G/F, Lecture Theatre 2, CUHK"
  v.latitude = 22.419073458962405
  v.longitude = 114.20680579473743
  v.features = { "projector" => true, "chalkboard" => true, "wifi" => true, "air_conditioning" => true, "microphone" => true }
  v.available_from = "08:00"
  v.available_until = "22:00"
  v.is_active = true
end

lsb_room = Venue.find_or_create_by!(tenant: math_dept, name: "LSB 222") do |v|
  v.description = "Small classroom for tutorials and office hours"
  v.capacity = 35
  v.location = "Lady Shaw Building (LSB), 2/F, Room 222, CUHK"
  v.latitude = 22.419073458962405
  v.longitude = 114.20680579473743
  v.features = { "whiteboard" => true, "wifi" => true, "air_conditioning" => true }
  v.available_from = "09:00"
  v.available_until = "20:00"
  v.is_active = true
end

lsb_501 = Venue.find_or_create_by!(tenant: math_dept, name: "LSB 501") do |v|
  v.description = "Computer classroom for computational mathematics"
  v.capacity = 50
  v.location = "Lady Shaw Building (LSB), 5/F, Room 501, CUHK"
  v.latitude = 22.419073458962405
  v.longitude = 114.20680579473743
  v.features = { "computers" => true, "projector" => true, "wifi" => true, "air_conditioning" => true }
  v.available_from = "08:30"
  v.available_until = "21:00"
  v.is_active = true
end

# -- Physics Department (Science Centre North Block, 科学馆北座) --
sc_nb_lt = Venue.find_or_create_by!(tenant: phys_dept, name: "SC N/B LT") do |v|
  v.description = "Physics lecture theatre with demonstration bench and built-in experiment setup"
  v.capacity = 180
  v.location = "Science Centre North Block, G/F, Lecture Theatre, CUHK"
  v.latitude = 22.419400307850857
  v.longitude = 114.2088384211826
  v.features = { "projector" => true, "microphone" => true, "demo_bench" => true, "wifi" => true, "air_conditioning" => true }
  v.available_from = "08:00"
  v.available_until = "22:00"
  v.is_active = true
end

sc_nb_101 = Venue.find_or_create_by!(tenant: phys_dept, name: "SC N/B 101") do |v|
  v.description = "Physics general teaching lab for undergraduate experiments"
  v.capacity = 36
  v.location = "Science Centre North Block, 1/F, Room 101, CUHK"
  v.latitude = 22.419400307850857
  v.longitude = 114.2088384211826
  v.features = { "lab_benches" => true, "oscilloscopes" => true, "wifi" => true, "fume_hood" => true }
  v.available_from = "09:00"
  v.available_until = "18:00"
  v.is_active = true
end

sc_nb_305 = Venue.find_or_create_by!(tenant: phys_dept, name: "SC N/B 305") do |v|
  v.description = "Seminar room for physics research group meetings"
  v.capacity = 25
  v.location = "Science Centre North Block, 3/F, Room 305, CUHK"
  v.latitude = 22.419400307850857
  v.longitude = 114.2088384211826
  v.features = { "projector" => true, "whiteboard" => true, "wifi" => true, "air_conditioning" => true }
  v.available_from = "09:00"
  v.available_until = "20:00"
  v.is_active = true
end

# -- Office of Student Affairs (各学生活动场地) --
rrs_hall = Venue.find_or_create_by!(tenant: osa, name: "Sir Run Run Shaw Hall") do |v|
  v.description = "Main university auditorium for concerts, ceremonies, and large events"
  v.capacity = 1438
  v.location = "Sir Run Run Shaw Hall, Central Campus, CUHK"
  v.latitude = 22.420348172393982
  v.longitude = 114.20714322341328
  v.features = { "stage" => true, "sound_system" => true, "lighting" => true, "projector" => true, "microphone" => true, "backstage" => true, "air_conditioning" => true }
  v.available_from = "08:00"
  v.available_until = "23:00"
  v.is_active = true
end

ch_multi = Venue.find_or_create_by!(tenant: osa, name: "Benjamin Franklin Centre MPC") do |v|
  v.description = "Multi-purpose court for sports events, exhibitions, and assemblies"
  v.capacity = 500
  v.location = "Benjamin Franklin Centre, Multi-Purpose Court, CUHK"
  v.latitude = 22.418346005491934
  v.longitude = 114.20534988477905
  v.features = { "court" => true, "sound_system" => true, "wifi" => true, "projector" => true, "portable_stage" => true }
  v.available_from = "07:00"
  v.available_until = "22:30"
  v.is_active = true
end

pomm_room = Venue.find_or_create_by!(tenant: osa, name: "Pommerenke Student Centre 201") do |v|
  v.description = "Student society meeting room with round-table setup"
  v.capacity = 30
  v.location = "Pommerenke Student Centre, 2/F, Room 201, CUHK"
  v.latitude = 22.417238586852275
  v.longitude = 114.20886685409607
  v.features = { "round_tables" => true, "wifi" => true, "whiteboard" => true, "air_conditioning" => true }
  v.available_from = "09:00"
  v.available_until = "22:00"
  v.is_active = true
end

uc_plaza = Venue.find_or_create_by!(tenant: osa, name: "UC Outdoor Plaza") do |v|
  v.description = "Open-air plaza in United College for bazaars, booths, and outdoor events"
  v.capacity = 300
  v.location = "United College Outdoor Plaza, CUHK"
  v.latitude = 22.42070
  v.longitude = 114.20395
  v.features = { "outdoor" => true, "power_outlets" => true, "wifi" => false }
  v.available_from = "08:00"
  v.available_until = "21:00"
  v.is_active = true
end

cc_pavilion = Venue.find_or_create_by!(tenant: osa, name: "Chung Chi Garden Pavilion") do |v|
  v.description = "Lake-side pavilion area for small outdoor events and gatherings"
  v.capacity = 80
  v.location = "Chung Chi College, Weiyuan Lake Pavilion, CUHK"
  v.latitude = 22.41545
  v.longitude = 114.21050
  v.features = { "outdoor" => true, "scenic" => true, "power_outlets" => true }
  v.available_from = "07:00"
  v.available_until = "20:00"
  v.is_active = true
end

# -- University Library (大学图书馆) --
lib_discuss_a = Venue.find_or_create_by!(tenant: lib, name: "University Library Discussion Room A") do |v|
  v.description = "Glass-walled discussion room for group study (max 8 people)"
  v.capacity = 8
  v.location = "University Library, 2/F, Discussion Room A, CUHK"
  v.latitude = 22.41968788636918
  v.longitude = 114.20509405731713
  v.features = { "whiteboard" => true, "wifi" => true, "air_conditioning" => true, "power_outlets" => true }
  v.available_from = "08:30"
  v.available_until = "22:00"
  v.is_active = true
end

lib_discuss_b = Venue.find_or_create_by!(tenant: lib, name: "University Library Discussion Room B") do |v|
  v.description = "Glass-walled discussion room for group study (max 8 people)"
  v.capacity = 8
  v.location = "University Library, 2/F, Discussion Room B, CUHK"
  v.latitude = 22.41968788636918
  v.longitude = 114.20509405731713
  v.features = { "whiteboard" => true, "wifi" => true, "air_conditioning" => true, "power_outlets" => true }
  v.available_from = "08:30"
  v.available_until = "22:00"
  v.is_active = true
end

lib_discuss_c = Venue.find_or_create_by!(tenant: lib, name: "University Library Discussion Room C") do |v|
  v.description = "Larger discussion room for project work (max 12 people)"
  v.capacity = 12
  v.location = "University Library, 3/F, Discussion Room C, CUHK"
  v.latitude = 22.41968788636918
  v.longitude = 114.20509405731713
  v.features = { "whiteboard" => true, "wifi" => true, "air_conditioning" => true, "projector" => true, "power_outlets" => true }
  v.available_from = "08:30"
  v.available_until = "22:00"
  v.is_active = true
end

lib_seminar = Venue.find_or_create_by!(tenant: lib, name: "University Library Seminar Room") do |v|
  v.description = "Library seminar room for workshops and information literacy sessions"
  v.capacity = 40
  v.location = "University Library, 4/F, Seminar Room, CUHK"
  v.latitude = 22.41972
  v.longitude = 114.20598
  v.features = { "projector" => true, "computers" => true, "wifi" => true, "air_conditioning" => true, "microphone" => true }
  v.available_from = "09:00"
  v.available_until = "21:00"
  v.is_active = true
end

lsk_study = Venue.find_or_create_by!(tenant: lib, name: "Li Ping Medical Library Study Room") do |v|
  v.description = "Quiet study room in Li Ping Medical Library"
  v.capacity = 6
  v.location = "Li Ping Medical Library, 1/F, Study Room, CUHK"
  v.latitude = 22.379386840677046
  v.longitude = 114.20097845409543
  v.features = { "wifi" => true, "air_conditioning" => true, "power_outlets" => true, "quiet_zone" => true }
  v.available_from = "09:00"
  v.available_until = "20:00"
  v.is_active = true
end

# === Equipment ===
Equipment.find_or_create_by!(tenant: cs_dept, name: "HD Projector") do |e|
  e.description = "Epson EB-2265U HD projector with HDMI/USB-C"
  e.quantity = 3
  e.equipment_type = "AV"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: cs_dept, name: "Wireless Microphone Set") do |e|
  e.description = "Shure BLX wireless microphone with receiver"
  e.quantity = 2
  e.equipment_type = "audio"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: cs_dept, name: "Portable Speaker") do |e|
  e.description = "JBL Eon One portable PA speaker"
  e.quantity = 4
  e.equipment_type = "audio"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: cs_dept, name: "Laptop") do |e|
  e.description = "Dell Latitude 5540 for presentations"
  e.quantity = 5
  e.equipment_type = "computer"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: cs_dept, name: "Webcam Kit") do |e|
  e.description = "Logitech Brio 4K webcam with tripod for hybrid meetings"
  e.quantity = 3
  e.equipment_type = "AV"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: ee_dept, name: "Oscilloscope") do |e|
  e.description = "Tektronix TBS2000B digital oscilloscope"
  e.quantity = 10
  e.equipment_type = "lab"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: ee_dept, name: "Signal Generator") do |e|
  e.description = "Keysight 33500B function/signal generator"
  e.quantity = 8
  e.equipment_type = "lab"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: ee_dept, name: "Multimeter") do |e|
  e.description = "Fluke 87V industrial true-RMS multimeter"
  e.quantity = 15
  e.equipment_type = "lab"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: math_dept, name: "Graphing Calculator") do |e|
  e.description = "Texas Instruments TI-84 Plus CE"
  e.quantity = 20
  e.equipment_type = "teaching"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: math_dept, name: "Document Camera") do |e|
  e.description = "ELMO MX-P2 document camera for handwritten demo"
  e.quantity = 3
  e.equipment_type = "AV"
  e.status = "available"
  e.is_active = true
end

# -- Physics Equipment --
Equipment.find_or_create_by!(tenant: phys_dept, name: "Laser Kit") do |e|
  e.description = "HeNe laser with optics bench for diffraction/interference experiments"
  e.quantity = 6
  e.equipment_type = "lab"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: phys_dept, name: "Geiger Counter") do |e|
  e.description = "Radiation detection meter for nuclear physics lab"
  e.quantity = 8
  e.equipment_type = "lab"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: phys_dept, name: "Digital Scale") do |e|
  e.description = "Mettler Toledo precision balance (0.001g)"
  e.quantity = 10
  e.equipment_type = "lab"
  e.status = "available"
  e.is_active = true
end

# -- OSA Equipment --
Equipment.find_or_create_by!(tenant: osa, name: "PA System") do |e|
  e.description = "Complete PA system with mixer, 2 speakers, and 4 wireless mics"
  e.quantity = 2
  e.equipment_type = "audio"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: osa, name: "Portable Stage") do |e|
  e.description = "Modular portable stage platform (2m x 1m per unit)"
  e.quantity = 6
  e.equipment_type = "event"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: osa, name: "Event Tent") do |e|
  e.description = "3m x 3m pop-up canopy tent for outdoor events"
  e.quantity = 8
  e.equipment_type = "event"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: osa, name: "Folding Table Set") do |e|
  e.description = "6-foot folding table with 4 chairs"
  e.quantity = 20
  e.equipment_type = "furniture"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: osa, name: "Banner Stand") do |e|
  e.description = "Roll-up retractable banner stand (0.8m x 2m)"
  e.quantity = 10
  e.equipment_type = "event"
  e.status = "available"
  e.is_active = true
end

# -- Library Equipment --
Equipment.find_or_create_by!(tenant: lib, name: "Noise-Cancelling Headphones") do |e|
  e.description = "Sony WH-1000XM5 for quiet study use (4-hour loan)"
  e.quantity = 12
  e.equipment_type = "accessory"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: lib, name: "iPad") do |e|
  e.description = "iPad Air with Apple Pencil for digital note-taking"
  e.quantity = 6
  e.equipment_type = "computer"
  e.status = "available"
  e.is_active = true
end

Equipment.find_or_create_by!(tenant: lib, name: "Portable Charger") do |e|
  e.description = "Anker 20000mAh portable power bank"
  e.quantity = 15
  e.equipment_type = "accessory"
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

Booking.find_or_create_by!(user: alice, venue: lsb_lt, title: "Math Tutoring Session") do |b|
  b.description = "Linear algebra review session"
  b.start_time = 4.days.from_now.change(hour: 15)
  b.end_time = 4.days.from_now.change(hour: 17)
  b.status = :pending
  b.contact_person = "Alice Wong"
  b.contact_email = "alice@cuhk.edu.hk"
  b.contact_phone = "91234567"
  b.estimated_attendance = 30
end

Booking.find_or_create_by!(user: evan, venue: sc_nb_lt, title: "Physics Demo Lecture") do |b|
  b.description = "Electromagnetic induction demonstration"
  b.start_time = 2.days.from_now.change(hour: 10)
  b.end_time = 2.days.from_now.change(hour: 12)
  b.status = :confirmed
  b.contact_person = "Evan Lau"
  b.contact_email = "evan@cuhk.edu.hk"
  b.contact_phone = "95556666"
  b.estimated_attendance = 80
end

Booking.find_or_create_by!(user: diana, venue: rrs_hall, title: "Annual Student Concert") do |b|
  b.description = "CUHK Student Union annual music concert"
  b.start_time = 5.days.from_now.change(hour: 19)
  b.end_time = 5.days.from_now.change(hour: 22)
  b.status = :pending
  b.contact_person = "Diana Cheung"
  b.contact_email = "diana@cuhk.edu.hk"
  b.contact_phone = "93334444"
  b.estimated_attendance = 800
end

Booking.find_or_create_by!(user: frank, venue: lib_discuss_a, title: "CSCI3100 Group Study") do |b|
  b.description = "Group study for database exam"
  b.start_time = 1.day.from_now.change(hour: 18)
  b.end_time = 1.day.from_now.change(hour: 21)
  b.status = :confirmed
  b.contact_person = "Frank Ng"
  b.contact_email = "frank@cuhk.edu.hk"
  b.contact_phone = "97778888"
  b.estimated_attendance = 6
end

Booking.find_or_create_by!(user: bob, venue: pomm_room, title: "Society Committee Meeting") do |b|
  b.description = "Monthly committee meeting for Computer Science Society"
  b.start_time = 3.days.from_now.change(hour: 17)
  b.end_time = 3.days.from_now.change(hour: 19)
  b.status = :confirmed
  b.contact_person = "Bob Chan"
  b.contact_email = "bob@cuhk.edu.hk"
  b.contact_phone = "98765432"
  b.estimated_attendance = 12
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
puts ""
puts "  Venues with coordinates:"
Venue.where.not(latitude: nil).each do |v|
  puts "    #{v.name} @ #{v.location} (#{v.latitude}, #{v.longitude})"
end
puts "  Tenants: #{Tenant.count}"
puts "  Users: #{User.count}"
puts "  Venues: #{Venue.count}"
puts "  Equipment: #{Equipment.count}"
puts "  Bookings: #{Booking.count}"
puts ""
puts "  Admin login: admin@cuhk.edu.hk / admin123"
puts "  User login:  alice@cuhk.edu.hk / password123"

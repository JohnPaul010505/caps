// ─── Member ──────────────────────────────────────────────────────────────────

class Member {
  final String  id;
  final String? userId;
  final String  fullName;
  final int?    age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? goal;
  final String  membershipStatus;
  final String? membershipType;
  final String? expirationDate;
  final String? trainerId;
  final String? contactNumber;
  final String? email;
  final String? emergencyContact;
  final bool    wantsTrainer;
  final DateTime? createdAt;

  const Member({
    required this.id,
    this.userId,
    required this.fullName,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.goal,
    required this.membershipStatus,
    this.membershipType,
    this.expirationDate,
    this.trainerId,
    this.contactNumber,
    this.email,
    this.emergencyContact,
    this.wantsTrainer = false,
    this.createdAt,
  });

  factory Member.fromMap(Map<String, dynamic> m) => Member(
    id:               m['id'] as String,
    userId:           m['user_id'] as String?,
    fullName:         m['full_name'] as String? ?? 'Unknown',
    age:              m['age'] as int?,
    gender:           m['gender'] as String?,
    height:           (m['height'] as num?)?.toDouble(),
    weight:           (m['weight'] as num?)?.toDouble(),
    goal:             m['goal'] as String?,
    membershipStatus: m['membership_status'] as String? ?? 'inactive',
    membershipType:   m['membership_type'] as String?,
    expirationDate:   m['expiration_date'] as String?,
    trainerId:        m['trainer_id'] as String?,
    contactNumber:    m['contact_number'] as String?,
    email:            m['email'] as String?,
    emergencyContact: m['emergency_contact'] as String?,
    wantsTrainer:     m['wants_trainer'] as bool? ?? false,
    createdAt:        m['created_at'] != null
        ? DateTime.tryParse(m['created_at'] as String)
        : null,
  );

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final exp  = DateTime.tryParse(expirationDate!);
    if (exp == null) return false;
    return exp.isBefore(DateTime.now().add(const Duration(days: 7)));
  }
}

// ─── Trainer ─────────────────────────────────────────────────────────────────

class Trainer {
  final String       id;
  final String?      userId;
  final String       fullName;
  final String?      specialty;
  final List<String> availableDays;
  final DateTime?    createdAt;

  const Trainer({
    required this.id,
    this.userId,
    required this.fullName,
    this.specialty,
    this.availableDays = const [],
    this.createdAt,
  });

  factory Trainer.fromMap(Map<String, dynamic> m) => Trainer(
    id:            m['id'] as String,
    userId:        m['user_id'] as String?,
    fullName:      m['full_name'] as String? ?? 'Unknown',
    specialty:     m['specialty'] as String?,
    availableDays: (m['available_days'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    createdAt: m['created_at'] != null
        ? DateTime.tryParse(m['created_at'] as String)
        : null,
  );
}

// ─── Message ─────────────────────────────────────────────────────────────────

class ChatMessage {
  final String   id;
  final String   senderId;
  final String   receiverId;
  final String   message;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
    id:         m['id'] as String,
    senderId:   m['sender_id'] as String,
    receiverId: m['receiver_id'] as String,
    message:    m['message'] as String? ?? '',
    timestamp:  DateTime.parse(m['timestamp'] as String),
  );
}

// ─── Workout Log ─────────────────────────────────────────────────────────────

class WorkoutLog {
  final String   id;
  final String   memberId;
  final String   workoutType;
  final int?     duration;       // minutes
  final int?     caloriesBurned;
  final String   date;

  const WorkoutLog({
    required this.id,
    required this.memberId,
    required this.workoutType,
    this.duration,
    this.caloriesBurned,
    required this.date,
  });

  factory WorkoutLog.fromMap(Map<String, dynamic> m) => WorkoutLog(
    id:             m['id'] as String,
    memberId:       m['member_id'] as String,
    workoutType:    m['workout_type'] as String? ?? '',
    duration:       m['duration'] as int?,
    caloriesBurned: m['calories_burned'] as int?,
    date:           m['date'] as String? ?? '',
  );
}

// ─── Meal Log ────────────────────────────────────────────────────────────────

class MealLog {
  final String id;
  final String memberId;
  final String mealType;   // breakfast | lunch | dinner | snack
  final String foodName;
  final int?   calories;
  final double? protein;
  final String date;

  const MealLog({
    required this.id,
    required this.memberId,
    required this.mealType,
    required this.foodName,
    this.calories,
    this.protein,
    required this.date,
  });

  factory MealLog.fromMap(Map<String, dynamic> m) => MealLog(
    id:       m['id'] as String,
    memberId: m['member_id'] as String,
    mealType: m['meal_type'] as String? ?? 'snack',
    foodName: m['food_name'] as String? ?? '',
    calories: m['calories'] as int?,
    protein:  (m['protein'] as num?)?.toDouble(),
    date:     m['date'] as String? ?? '',
  );
}

/// Represents a User object with various user details.
class User {
  final String userID;
  final String password;
  final String? address;
  final String? birthDate;
  final String email;
  final String name;
  final String? pNum;
  final String? userType;
  final double? rating;
  final String username;

  /// Constructor to initialize a User object.
  User({
    required this.userID,
    required this.password,
    this.address,
    this.birthDate,
    required this.email,
    required this.name,
    this.pNum,
    this.userType,
    this.rating,
    required this.username,
  });

  /// Factory constructor to create a User object from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['User ID'],
      password: json['Password'],
      address: json['Address'],
      birthDate: json['Birth Date'],
      email: json['Email'],
      name: json['Name'],
      pNum: json['Phone Number'],
      userType: json['Type'],
      rating: json['Rating'] != null ? (json['Rating'] as num).toDouble() : null,
      username: json['Username'],
    );
  }

  /// Converts a User object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'User ID': userID,
      'Password': password,
      'Address': address,
      'Birth Date': birthDate,
      'Email': email,
      'Name': name,
      'Phone Number': pNum,
      'Type': userType,
      if (rating != null) 'Rating': rating,
      'Username': username,
    };
  }
}

/// Represents a Login model with validation logic.
class LoginModel {
  final String email;  // Username for login
  final String password;  // Password for login

  /// Constructor to initialize a LoginModel object.
  LoginModel({
    required this.email,
    required this.password,
  });

  /// Checks if the login credentials are valid.
  bool isValid() {
    return _isValidEmail(email) && _isValidPassword(password);
  }
  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)[A-Za-z\d@$!%*?&]{6,}$');
    return regex.hasMatch(password);
  }
  
  /// Validates the email format.
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }
}

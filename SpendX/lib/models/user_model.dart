class User {
  final String name;
  final String username;
  final String mobile;

  User({
    required this.name,
    required this.username,
    required this.mobile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      username: json['username'],
      mobile: json['mobile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'mobile': mobile,
    };
  }
}

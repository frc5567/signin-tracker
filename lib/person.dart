/// Models a person with name, sign in and sign out
class Person {
  late String name;
  late DateTime signIn;
  late DateTime signOut;

  /// Constructor, requires name and signIn on construct
  Person({required this.name, required this.signIn});

  /// Converts the data to a list for CSV output
  List<dynamic> toList() {
    List<dynamic> list = [name, signIn, signOut];
    return list;
  }
}

class Person {
  late String name;
  late DateTime signIn;
  late DateTime signOut;

  Person({
    required this.name,
    required this.signIn
});

  List<dynamic> toList() {
    List<dynamic> list = [name, signIn, signOut];
    return list;
  }
}
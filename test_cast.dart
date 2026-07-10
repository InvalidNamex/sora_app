void main() {
  List<dynamic> dynList = ['a', 'b'];
  var casted = dynList.cast<String>();
  print(casted is List<String>);
}

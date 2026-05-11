import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  static final FirebaseFunctions instance =
  FirebaseFunctions.instanceFor(region: 'us-central1');
}
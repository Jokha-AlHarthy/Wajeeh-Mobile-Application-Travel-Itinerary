class FormValidators{
  static String? validateFullName(String? value){
    if(value == null || value.isEmpty){
      return 'Please enter your full name';
    }
    if(RegExp(r'^[0-9]+$').hasMatch(value)){
      return 'Full name cannot be just numbers';
    }
    return null;
  }

  static String? validatePhone(String? value){
    if(value == null || value.isEmpty){
      return 'Please enter your Phone Number';
    }
    if(!RegExp(r'^[0-9]{8,9}$').hasMatch(value)){
      return 'Phone Number must be 8 or 9 digits';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your Email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid Email';
    }
    return null;
  }

}

# signin_tracker_5567

An app to track sign in and out for Robotics practices

To use, input your name in the "input name" field and tap "sign in"
To sign out, select your name form the dropdown and tap sign out

Data formatting:
The data is outputted as a csv to the External Storage (android/data/com.frc5567.signin_tracker_5567/files).
The first column is the username, the second is sign in time, and the third is sign out. There will be a
row labelled "Select your name" with a sign in time, that was when the app was launched.

To deploy - see https://docs.flutter.dev/deployment/android
You don't need to do all the signing steps for local deployment, just 
```
flutter build apk --release
flutter install
```


### TODO
 - Documentation
 - When do we write data? Right now write data on app close
 - Icon
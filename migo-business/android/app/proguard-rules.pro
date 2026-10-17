# mobile_scanner ക്ലാസുകൾ നിലനിർത്തുക (ക്യാമറ പ്രശ്നം പരിഹരിക്കാൻ)
-keep class dev.steenbakker.mobile_scanner.** { *; }

# R8-ന്റെ തെറ്റായ മുന്നറിയിപ്പുകൾ അവഗണിക്കുക (Flutter Play Core dependency)
-dontwarn com.google.android.play.core.**
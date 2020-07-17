# ca.dpogue.cambie

## Requirements
* Android SDK Platform 21 (Lollipop)
* Android Build Tools 21+
* Android Support Library v21+

## Installing

```
cordova create projectname
cd ./projectname
cordova platform add ios
cordova platform add android@master --usegit
cordova plugin add git+ssh://git@bitbucket.org:ayogo/cordova-plugin-cambie.git
cordova build
```

## Preferences

**CambieTheme:**  
The programmatic name of the Android Theme to use. This should be one of the
AppCompat themes (or a theme derived from them).
This must be the fully qualified name of a resource (i.e.,
`"android.support.v7.appcompat.R.style.Theme_AppCompat_Light"`).

**CambieUseToolbar:** (Android Only)  
Use a Toolbar instead of an ActionBar. If you're using a Toolbar, you must use
a theme that does not include an ActionBar, otherwise your app will crash!

**CambieNavType:**  
"drawer" or "tabs" (default is "drawer" for Android, "tabs" for iOS)

**CambieDrawerBackground:**  
An integer representing the ARGB colour for the drawer background.

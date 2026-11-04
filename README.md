# Catalogue AI

Setup coming.

## Backend setup

Before starting the backend, copy the example configuration:

```sh
cp backend/.env.example backend/.env
```

## Folder layout

```text
backend/
ios/
  CatalogueCore/
  CatalogueApp/
```

## Regenerating the project

```sh
cd ios && xcodegen
```

## Running on iOS

In Xcode, choose any iPhone simulator and press Run.

For the command line: `xcrun simctl list devices available`, then use that name in `xcodebuild -destination`.

Example:

```sh
xcodebuild -project ios/CatalogueApp.xcodeproj -scheme CatalogueApp -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.0' -derivedDataPath ios/build/DerivedData build test
```

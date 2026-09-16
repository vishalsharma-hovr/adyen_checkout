# Local development

## Location

```text
~/Documents/packages/adyen_checkout/
```

## Host app path override

In the host app `pubspec.yaml`:

```yaml
dependencies:
  adyen_checkout:
    path: ../../../Documents/packages/adyen_checkout

# Or keep a Git dep and override:
# dependency_overrides:
#   adyen_checkout:
#     path: ../../../Documents/packages/adyen_checkout
```

Adjust the relative path to match your app’s location under `StudioProjects/`.

Then:

```bash
fvm flutter pub get
```

## Plugin example

```bash
cd ~/Documents/packages/adyen_checkout
fvm flutter pub get
fvm flutter test
cd example && fvm flutter pub get
```

Example assets under `example/assets/adyen/` use **placeholders only**.

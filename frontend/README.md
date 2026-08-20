# Skill building game frontend

The app records completed and explicitly abandoned gameplay locally, then
attempts to synchronize the durable queue at startup and after every new
record. Network failures do not interrupt gameplay.

The development API defaults to `http://localhost:8000` with `dev-key`, matching
the normal Linux debug workflow. For a physical tablet, supply the backend
computer's LAN address when running or building:

```sh
flutter run \
  --dart-define=GAMEPLAY_API_BASE_URL=http://192.168.1.10:8000 \
  --dart-define=GAMEPLAY_API_KEY=dev-key
```

The preliminary API uses cleartext HTTP on the local network, so the Android
manifest permits it. Replace this configuration together with the disposable
pre-pilot backend before the authenticated pilot.

# TNT Defect Register

| ID | Severity | Feature | Reproduction steps | Root cause | Fix | Regression test | Test result | Remaining risk |
|----|----------|---------|--------------------|------------|-----|-----------------|-------------|----------------|
| 1 | P1 | Android Build | Run `flutter build apk --debug` in the current folder | The folder name `tnt---tamil-calendar-&-panchangam (1)` contains `&` and spaces which breaks Windows `cmd.exe` execution of Gradle wrapper | None applied in code | N/A | FAIL | Rename the folder to `tnt_tamil_calendar` locally |
| 2 | P0 | Staging E2E | Cannot run live integration tests | `.env.staging` contains placeholder `SUPABASE_ANON_KEY` and invalid URL. No emulator provided. | None | N/A | BLOCKED | High risk: The UI and backend have not been tested end-to-end dynamically |

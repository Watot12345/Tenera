# Keep RoomDatabase generated *_Impl constructors under AGP 9 / R8 full mode.
# Older androidx.room consumer rules only keep the class name without `<init>()`,
# causing R8 full mode to strip `androidx.work.impl.WorkDatabase_Impl.<init>()`
# and crash on startup inside `androidx.startup.InitializationProvider`.
-keep class * extends androidx.room.RoomDatabase {
    <init>();
}

# Keep WorkManager reflective constructors under R8 full mode.
-keep class * extends androidx.work.InputMerger {
    <init>();
}
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

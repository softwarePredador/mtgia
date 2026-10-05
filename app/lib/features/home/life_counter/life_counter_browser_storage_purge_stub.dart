/// Native builds keep every life counter key in SharedPreferences.
int purgeBrowserLocalStorage(bool Function(String key) shouldRemove) => 0;

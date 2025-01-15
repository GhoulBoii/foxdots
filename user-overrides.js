// Privacy-Focused
user_pref("browser.startup.page", 3);                                           // Resumes previous session
user_pref("browser.download.start_downloads_in_tmp_dir", false);                // Don't start downloads in tmp dir
user_pref("browser.search.separatePrivateDefault", false);                      // Same search engine for both modes
user_pref("browser.search.separatePrivateDefault.ui.enabled", false);           // Removes option for PB search engine
user_pref("privacy.clearOnShutdown.history", false);                            // Don't clear history on shutdown
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);               // Don't clear cookies on shutdown
user_pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", false);     // Don't clear history on shutdown [FF128+]

// Customisation
user_pref("browser.display.use_system_colors", false);                          // Do not use default dark mode or light mode
user_pref("extensions.pocket.enabled", false);                                  // Disable Pocket
user_pref("browser.tabs.firefox-view", false);                                  // Disable Firefox View
user_pref("general.autoScroll", true);                                          // Enable auto scrolling
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);         // Enable userchrome.css
user_pref("signon.rememberSignons", false);                                     // Disable saving passwords
user_pref("browser.urlbar.update2.engineAliasRefresh", true);                   // Add button to add custom search engines
user_pref("image.http.accept", "*/*");                                          // Disable webp


import React, { useState } from 'react';
import {
  Platform,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  useColorScheme,
} from 'react-native';
import DeviceInfo from 'react-native-device-info';
import OSAMModule, { type OSAMLanguage } from 'react-native-modul-comu-osam';
import libPkg from 'react-native-modul-comu-osam/package.json';
import appPkg from './package.json';

const BUNDLE_ID = DeviceInfo.getBundleId();
const LIB_INSTALLED_VERSION = libPkg.version;
const LIB_DEPENDENCY_SPEC =
  appPkg.dependencies['react-native-modul-comu-osam'];
const LANGUAGES: OSAMLanguage[] = ['ca', 'es', 'en'];

type Result = { label: string; value: string; ok: boolean };

function App(): React.JSX.Element {
  const systemDark = useColorScheme() === 'dark';
  const [results, setResults] = useState<Result[]>([]);
  const [lang, setLang] = useState<OSAMLanguage>('en');
  const [isDarkMode, setIsDarkMode] = useState<boolean>(systemDark);
  const isDark = isDarkMode;

  const record = (label: string, value: unknown, ok: boolean) => {
    setResults((prev) => [
      { label, value: typeof value === 'string' ? value : JSON.stringify(value, null, 2), ok },
      ...prev,
    ]);
  };

  const run = async (label: string, fn: () => Promise<unknown>) => {
    try {
      const out = await fn();
      record(label, out, true);
    } catch (e) {
      record(label, e instanceof Error ? e.message : String(e), false);
    }
  };

  const darkLabel = isDarkMode ? 'dark' : 'light';
  const actions: Array<{ title: string; onPress: () => void }> = [
    { title: 'appInformation()', onPress: () => run('appInformation', () => OSAMModule.appInformation()) },
    { title: 'deviceInformation()', onPress: () => run('deviceInformation', () => OSAMModule.deviceInformation()) },
    { title: `versionControl('${lang}', ${darkLabel})`, onPress: () => run(`versionControl('${lang}', ${darkLabel})`, () => OSAMModule.versionControl(lang, isDarkMode)) },
    { title: `rating('${lang}', ${darkLabel})`, onPress: () => run(`rating('${lang}', ${darkLabel})`, () => OSAMModule.rating(lang, isDarkMode)) },
    { title: `changeLanguageEvent('${lang}')`, onPress: () => run(`changeLanguageEvent('${lang}')`, () => OSAMModule.changeLanguageEvent(lang)) },
    { title: `firstTimeOrUpdateEvent('${lang}')`, onPress: () => run(`firstTimeOrUpdateEvent('${lang}')`, () => OSAMModule.firstTimeOrUpdateEvent(lang)) },
    { title: "subscribeToCustomTopic('demo')", onPress: () => run("subscribeToCustomTopic('demo')", () => OSAMModule.subscribeToCustomTopic('demo')) },
    { title: "unsubscribeToCustomTopic('demo')", onPress: () => run("unsubscribeToCustomTopic('demo')", () => OSAMModule.unsubscribeToCustomTopic('demo')) },
    { title: 'getFCMToken()', onPress: () => run('getFCMToken', () => OSAMModule.getFCMToken()) },
    { title: 'isOnline()', onPress: () => run('isOnline', () => OSAMModule.isOnline()) },
  ];

  const bg = { backgroundColor: isDark ? '#111' : '#f5f5f5' };
  const fg = { color: isDark ? '#fff' : '#111' };
  const segBorder = isDark ? '#333' : '#ddd';

  return (
    <SafeAreaView style={[styles.safe, bg]}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={[styles.title, fg]}>react-native-modul-comu-osam</Text>
        <Text style={[styles.subtitle, fg]}>Example smoke-test app</Text>
        <View style={[styles.meta, { borderColor: segBorder }]}>
          <Text style={[styles.metaRow, fg]}>
            <Text style={styles.metaKey}>
              {Platform.OS === 'ios' ? 'Bundle ID' : 'Application ID'}:{' '}
            </Text>
            {BUNDLE_ID}
          </Text>
          <Text style={[styles.metaRow, fg]}>
            <Text style={styles.metaKey}>Library dependency: </Text>
            {LIB_DEPENDENCY_SPEC}
          </Text>
          <Text style={[styles.metaRow, fg]}>
            <Text style={styles.metaKey}>Library resolved: </Text>
            {LIB_INSTALLED_VERSION}
          </Text>
        </View>

        <View style={styles.controlsRow}>
          <Text style={[styles.controlsLabel, fg]}>Language</Text>
          <View style={[styles.segmented, { borderColor: segBorder }]}>
            {LANGUAGES.map((code) => {
              const active = code === lang;
              return (
                <TouchableOpacity
                  key={code}
                  onPress={() => setLang(code)}
                  style={[
                    styles.segment,
                    active && styles.segmentActive,
                  ]}
                >
                  <Text
                    style={[
                      styles.segmentText,
                      { color: active ? '#fff' : isDark ? '#ddd' : '#333' },
                    ]}
                  >
                    {code.toUpperCase()}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </View>

        <View style={styles.controlsRow}>
          <Text style={[styles.controlsLabel, fg]}>Dark mode</Text>
          <TouchableOpacity
            style={[
              styles.toggle,
              { borderColor: segBorder, backgroundColor: isDarkMode ? '#2563eb' : 'transparent' },
            ]}
            onPress={() => setIsDarkMode((v) => !v)}
          >
            <Text
              style={[
                styles.toggleText,
                { color: isDarkMode ? '#fff' : isDark ? '#ddd' : '#333' },
              ]}
            >
              {isDarkMode ? 'ON' : 'OFF'}
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.buttons}>
          {actions.map((a) => (
            <TouchableOpacity key={a.title} style={styles.button} onPress={a.onPress}>
              <Text style={styles.buttonText}>{a.title}</Text>
            </TouchableOpacity>
          ))}
          <TouchableOpacity style={[styles.button, styles.clear]} onPress={() => setResults([])}>
            <Text style={styles.buttonText}>Clear</Text>
          </TouchableOpacity>
        </View>
        <View style={styles.results}>
          {results.length === 0 ? (
            <Text style={[styles.empty, fg]}>No calls yet.</Text>
          ) : (
            results.map((r, i) => (
              <View
                key={`${r.label}-${i}`}
                style={[
                  styles.resultRow,
                  { backgroundColor: r.ok ? '#2b8a3e22' : '#c9252522' },
                ]}
              >
                <Text style={[styles.resultLabel, fg]}>
                  {r.ok ? '✓' : '✗'} {r.label}
                </Text>
                <Text style={[styles.resultValue, fg]}>{r.value}</Text>
              </View>
            ))
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  content: { padding: 20, paddingBottom: 60 },
  title: { fontSize: 22, fontWeight: '700' },
  subtitle: { fontSize: 14, opacity: 0.7, marginBottom: 16 },
  meta: {
    padding: 12,
    borderWidth: 1,
    borderRadius: 8,
    marginBottom: 16,
    gap: 4,
  },
  metaRow: { fontSize: 12, fontFamily: 'Courier' },
  metaKey: { fontWeight: '700' },
  controlsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  controlsLabel: { fontSize: 14, fontWeight: '600' },
  segmented: {
    flexDirection: 'row',
    borderWidth: 1,
    borderRadius: 8,
    overflow: 'hidden',
  },
  segment: {
    paddingVertical: 8,
    paddingHorizontal: 16,
    minWidth: 56,
    alignItems: 'center',
  },
  segmentActive: { backgroundColor: '#2563eb' },
  segmentText: { fontWeight: '600', fontSize: 13 },
  toggle: {
    paddingVertical: 8,
    paddingHorizontal: 20,
    borderWidth: 1,
    borderRadius: 8,
    minWidth: 72,
    alignItems: 'center',
  },
  toggleText: { fontWeight: '700', fontSize: 13 },
  buttons: { gap: 8, marginBottom: 16 },
  button: {
    backgroundColor: '#2563eb',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
  },
  clear: { backgroundColor: '#666' },
  buttonText: { color: '#fff', fontWeight: '600', textAlign: 'center' },
  results: { gap: 8 },
  empty: { fontStyle: 'italic', opacity: 0.6 },
  resultRow: { padding: 12, borderRadius: 8, gap: 4 },
  resultLabel: { fontWeight: '700' },
  resultValue: { fontFamily: 'Courier', fontSize: 12 },
});

export default App;

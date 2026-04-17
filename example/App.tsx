import React, { useState } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  useColorScheme,
} from 'react-native';
import OSAMModule from 'react-native-modul-comu-osam';

type Result = { label: string; value: string; ok: boolean };

function App(): React.JSX.Element {
  const isDark = useColorScheme() === 'dark';
  const [results, setResults] = useState<Result[]>([]);

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

  const actions: Array<{ title: string; onPress: () => void }> = [
    { title: 'getAppInformation()', onPress: () => run('getAppInformation', () => OSAMModule.getAppInformation()) },
    { title: 'getDeviceInformation()', onPress: () => run('getDeviceInformation', () => OSAMModule.getDeviceInformation()) },
    { title: "checkVersionControl('en')", onPress: () => run("checkVersionControl('en')", () => OSAMModule.checkVersionControl('en')) },
    { title: "showRatingDialog('en')", onPress: () => run("showRatingDialog('en')", () => OSAMModule.showRatingDialog('en')) },
  ];

  const bg = { backgroundColor: isDark ? '#111' : '#f5f5f5' };
  const fg = { color: isDark ? '#fff' : '#111' };

  return (
    <SafeAreaView style={[styles.safe, bg]}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={[styles.title, fg]}>react-native-modul-comu-osam</Text>
        <Text style={[styles.subtitle, fg]}>Example smoke-test app</Text>
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

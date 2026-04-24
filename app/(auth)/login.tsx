import { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import { Colors } from '../../constants/colors';
import { supabase } from '../../lib/supabase';

export default function LoginScreen() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [mode, setMode] = useState<'login' | 'signup'>('login');

  const handleEmailAuth = async () => {
    if (!email || !password) {
      Alert.alert('Error', 'Email y contraseña son requeridos.');
      return;
    }

    setLoading(true);
    try {
      const { error } =
        mode === 'login'
          ? await supabase.auth.signInWithPassword({ email, password })
          : await supabase.auth.signUp({ email, password });

      if (error) Alert.alert('Error', error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleAuth = async () => {
    setLoading(true);
    try {
      const { error } = await supabase.auth.signInWithOAuth({
        provider: 'google',
        options: { redirectTo: 'senfi://auth/callback' },
      });
      if (error) Alert.alert('Error', error.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={styles.header}>
        <Text style={styles.logo}>senfi</Text>
        <Text style={styles.tagline}>Tus finanzas, claras.</Text>
      </View>

      <View style={styles.form}>
        <TextInput
          style={styles.input}
          placeholder="Email"
          placeholderTextColor={Colors.TextMuted}
          value={email}
          onChangeText={setEmail}
          autoCapitalize="none"
          keyboardType="email-address"
          editable={!loading}
        />
        <TextInput
          style={styles.input}
          placeholder="Contraseña"
          placeholderTextColor={Colors.TextMuted}
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          editable={!loading}
        />

        <TouchableOpacity
          style={[styles.button, styles.primaryButton, loading && styles.disabled]}
          onPress={handleEmailAuth}
          disabled={loading}
        >
          {loading ? (
            <ActivityIndicator color={Colors.White} />
          ) : (
            <Text style={styles.buttonText}>
              {mode === 'login' ? 'Iniciar sesión' : 'Crear cuenta'}
            </Text>
          )}
        </TouchableOpacity>

        <View style={styles.divider}>
          <View style={styles.dividerLine} />
          <Text style={styles.dividerText}>o</Text>
          <View style={styles.dividerLine} />
        </View>

        <TouchableOpacity
          style={[styles.button, styles.googleButton, loading && styles.disabled]}
          onPress={handleGoogleAuth}
          disabled={loading}
        >
          <Text style={styles.googleButtonText}>Continuar con Google</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.switchMode}
          onPress={() => setMode(mode === 'login' ? 'signup' : 'login')}
        >
          <Text style={styles.switchText}>
            {mode === 'login' ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión'}
          </Text>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.Background,
    justifyContent: 'center',
    paddingHorizontal: 24,
  },
  header: {
    alignItems: 'center',
    marginBottom: 48,
  },
  logo: {
    fontSize: 42,
    fontWeight: '700',
    color: Colors.Primary,
    letterSpacing: -1,
  },
  tagline: {
    fontSize: 16,
    color: Colors.TextSecondary,
    marginTop: 8,
  },
  form: {
    gap: 12,
  },
  input: {
    backgroundColor: Colors.Surface,
    borderWidth: 1,
    borderColor: Colors.Border,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 16,
    color: Colors.TextPrimary,
  },
  button: {
    borderRadius: 12,
    paddingVertical: 16,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 4,
  },
  primaryButton: {
    backgroundColor: Colors.Primary,
  },
  googleButton: {
    backgroundColor: Colors.Surface,
    borderWidth: 1,
    borderColor: Colors.Border,
  },
  buttonText: {
    color: Colors.White,
    fontSize: 16,
    fontWeight: '600',
  },
  googleButtonText: {
    color: Colors.TextPrimary,
    fontSize: 16,
    fontWeight: '500',
  },
  disabled: {
    opacity: 0.6,
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginVertical: 4,
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: Colors.Border,
  },
  dividerText: {
    marginHorizontal: 12,
    color: Colors.TextMuted,
    fontSize: 14,
  },
  switchMode: {
    alignItems: 'center',
    marginTop: 8,
  },
  switchText: {
    color: Colors.Primary,
    fontSize: 14,
  },
});

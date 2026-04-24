import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Colors } from '../../constants/colors';
import { useAuthStore } from '../../stores/authStore';

export default function DashboardScreen() {
  const { user, signOut } = useAuthStore();

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.greeting}>Hola,</Text>
        <Text style={styles.email}>{user?.email ?? 'Usuario'}</Text>
      </View>

      <View style={styles.placeholder}>
        <Text style={styles.placeholderIcon}>📊</Text>
        <Text style={styles.placeholderTitle}>Dashboard</Text>
        <Text style={styles.placeholderText}>
          Aquí verás tu resumen financiero.{'\n'}Próximamente.
        </Text>
      </View>

      <TouchableOpacity style={styles.signOutButton} onPress={signOut}>
        <Text style={styles.signOutText}>Cerrar sesión</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.Background,
    paddingHorizontal: 24,
    paddingTop: 60,
    paddingBottom: 32,
  },
  header: {
    marginBottom: 40,
  },
  greeting: {
    fontSize: 16,
    color: Colors.TextSecondary,
  },
  email: {
    fontSize: 22,
    fontWeight: '700',
    color: Colors.TextPrimary,
    marginTop: 4,
  },
  placeholder: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  placeholderIcon: {
    fontSize: 56,
    marginBottom: 16,
  },
  placeholderTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: Colors.TextPrimary,
    marginBottom: 8,
  },
  placeholderText: {
    fontSize: 15,
    color: Colors.TextSecondary,
    textAlign: 'center',
    lineHeight: 22,
  },
  signOutButton: {
    backgroundColor: Colors.Surface,
    borderWidth: 1,
    borderColor: Colors.Border,
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: 'center',
  },
  signOutText: {
    color: Colors.Error,
    fontSize: 16,
    fontWeight: '500',
  },
});

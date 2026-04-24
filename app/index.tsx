import { Redirect } from 'expo-router';
import { useAuthStore } from '../stores/authStore';
import { View, ActivityIndicator } from 'react-native';
import { Colors } from '../constants/colors';

export default function Index() {
  const { session, loading } = useAuthStore();

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: Colors.Background }}>
        <ActivityIndicator size="large" color={Colors.Primary} />
      </View>
    );
  }

  return session ? <Redirect href="/(app)/dashboard" /> : <Redirect href="/(auth)/login" />;
}

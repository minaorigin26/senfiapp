import { Stack, Redirect } from 'expo-router';
import { useAuthStore } from '../../stores/authStore';

export default function AppLayout() {
  const { session, loading } = useAuthStore();

  if (!loading && !session) {
    return <Redirect href="/(auth)/login" />;
  }

  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="dashboard" />
    </Stack>
  );
}

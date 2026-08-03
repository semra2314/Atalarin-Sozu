import { Stack } from "expo-router";

export default function RootLayout() {
  return (
    // Root navigation stack
    <Stack>
      {/* Main tab navigator */}
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
    </Stack>
  );
}

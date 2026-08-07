import AsyncStorage from "@react-native-async-storage/async-storage";
import { useRouter } from "expo-router";
import { useEffect, useState } from "react";
import { ActivityIndicator, View } from "react-native";

export default function Index() {
  const router = useRouter();
  const [isChecking, setIsChecking] = useState(true);

  useEffect(() => {
    const checkFirstLaunch = async () => {
      try {
        // Temporary: Reset the launch state to test the onboarding flow.
        await AsyncStorage.removeItem("@alreadyLaunched");

        const value = await AsyncStorage.getItem("@alreadyLaunched");

        if (value === null) {
          // First app launch. Persist the launch flag and navigate to onboarding.
          await AsyncStorage.setItem("@alreadyLaunched", "true");
          router.replace("/onboarding");
        } else {
          // App has been launched before. Navigate directly to the main application.
          router.replace("/(tabs)");
        }
      } catch (error) {
        // Fallback to the main application if the launch state cannot be determined.
        console.error("Error reading AsyncStorage:", error);
        router.replace("/(tabs)");
      }
    };

    checkFirstLaunch();
  }, [router]);

  // Display a loading indicator while the launch state is being resolved.
  return (
    <View
      style={{
        flex: 1,
        justifyContent: "center",
        alignItems: "center",
        backgroundColor: "#fff",
      }}
    >
      <ActivityIndicator />
    </View>
  );
}

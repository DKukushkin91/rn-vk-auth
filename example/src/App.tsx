import { Text, View, StyleSheet, Button } from 'react-native';
import { RnVkAuth } from 'rn-vk-auth';

export default function App() {
  const fetchApi = async (data: {
    code: string;
    codeVerifier: string;
    deviceId: string;
    redirectURI: string;
  }) => {
    const response = await fetch(
      'https://api-beta.dapognali.ru/v1/vk/redirect',
      { method: 'GET' }
    );
    const responseJson = await response.json();

    console.log('Отправка бэку', data);
    console.log('Ответ бэка', responseJson);

    return responseJson;
  };

  const handlePress = async () => {
    try {
      const vkid = await RnVkAuth.initialize({
        clientId: '51863908',
        clientSecret: 'kWtTGlS0uBtslfwHDCCv',
        loggingEnabled: __DEV__,
      });

      if (vkid) {
        const bottomSheet = await RnVkAuth.toggleOneTapBottomSheet(
          {
            serviceName: 'Имя сервиса',
            cornerRadius: 8,
            autoDismissOnSuccess: true,
            scope: [
              'first_name',
              'phone',
              'avatar',
              'email',
              'sex',
              'birthday',
            ],
          },
          fetchApi
        );

        console.log('toggelBottom', bottomSheet);
      }
    } catch (error) {
      console.error(error);
    }
  };

  const handleLogout = async () => {
    try {
      const result = await RnVkAuth.logout();

      console.log('LOGOUT', result);
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <View style={styles.container}>
      <Text>Auth VK</Text>
      <Button title={'VK Auth'} onPress={handlePress} />

      <Button title={'VK LOGOUT'} onPress={handleLogout} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});

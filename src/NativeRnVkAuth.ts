import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

interface IInitializeParams {
  clientId: string;
  clientSecret: string;
  loggingEnabled: boolean;
}

interface IInitializeResult {
  success: boolean;
  result?: string;
  error?: string;
  code?: string;
}

interface IToggleOneTapBottomSheetParams {
  serviceName: string;
  cornerRadius: number;
  autoDismissOnSuccess: boolean;
  // [first_name, last_name, phone, avatar, email, sex, birthday]
  scope: string[];
}

interface IToggleOneTapBottomSheetResult {
  success: boolean;
  result?: {
    expirationDate: string;
    scope: string[];
    userId: number;
    accessToken: string;
  };
  error?: string;
  code?: string;
}

interface IFetchApiParams {
  code: string;
  codeVerifier: string;
  deviceId: string;
  redirectURI: string;
}

interface ILogoutResult {
  success: boolean;
  result?: string;
  error?: string;
  code?: string;
}

export interface Spec extends TurboModule {
  initialize: (params: IInitializeParams) => Promise<IInitializeResult>;
  toggleOneTapBottomSheet: (
    params: IToggleOneTapBottomSheetParams,
    fetchApi: (data: IFetchApiParams) => Promise<unknown>
  ) => Promise<IToggleOneTapBottomSheetResult>;
  logout: () => Promise<ILogoutResult>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('RnVkAuth');

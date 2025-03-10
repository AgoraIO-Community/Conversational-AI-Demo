import { isCN } from '@/lib/utils'

export const LOCAL_SETTINGS_KEY = `SETTINGS-${isCN ? 'CN' : 'GLOBAL'}-CONVOAI`
export const HEARTBEAT_INTERVAL = 1000 * 10
export const FIRST_START_TIMEOUT = 1000 * 30
export const FIRST_START_TIMEOUT_DEV = 1000 * 30 // 30s for dev
export const AGENT_RECONNECT_TIMEOUT = 1000 * 120
export const DEFAULT_CONVERSATION_DURATION = 60 * 10 // 10 minutes

export const CONSOLE_CN_URL = 'https://console.shengwang.cn'
export const CONSOLE_EN_URL = 'https://console.agora.io'
export const CONSOLE_URL = isCN ? CONSOLE_CN_URL : CONSOLE_EN_URL
export const CONSOLE_IMG_URL = isCN
  ? '/img/console-zh-20250227.png'
  : '/img/console-en-20250227.png'
export const CONSOLE_IMG_WIDTH = 632
export const CONSOLE_IMG_HEIGHT = 160
export const TERMS_LINK = isCN ? '/terms/service/' : 'https://www.agora.io/en/terms-of-service/'
export const POLICY_LINK = isCN ? '/terms/privacy/' : 'https://www.agora.io/en/privacy-policy/'

export * from '@/constants/agent/schema'

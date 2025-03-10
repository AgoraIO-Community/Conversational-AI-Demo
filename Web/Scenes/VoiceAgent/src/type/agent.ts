import * as z from 'zod'

import { agentPresetSchema } from '@/constants/agent/schema'

export type IAgentPreset = z.infer<typeof agentPresetSchema>


export type IUploadLogInput = {
  content: {
    appId: string,
    channelName: string,
    agentId: string,
    payload?: Record<string, string | number | boolean>,
  },
  file: File | null,
}
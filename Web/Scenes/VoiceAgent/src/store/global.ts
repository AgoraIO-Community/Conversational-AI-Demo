import { create } from 'zustand'

export interface IGlobalStore {
  showSidebar: boolean
  setShowSidebar: (showSidebar: boolean) => void
  onClickSidebar: () => void
  showSubtitle: boolean
  setShowSubtitle: (showSubtitle: boolean) => void
  onClickSubtitle: () => void
  isDevMode: boolean
  setIsDevMode: (isDevMode: boolean) => void
  isRTCCompatible: boolean
  showCompatibilityDialog: boolean
  setShowCompatibilityDialog: (showCompatibilityDialog: boolean) => void
  setIsRTCCompatible: (isRTCCompatible: boolean) => void
  showTimeoutDialog: boolean
  setShowTimeoutDialog: (showTimeoutDialog: boolean) => void
  showLoginPanel: boolean
  setShowLoginPanel: (showLoginPanel: boolean) => void
}

export const useGlobalStore = create<IGlobalStore>((set) => ({
  showSidebar: false,
  setShowSidebar: (showSidebar: boolean) => set({ showSidebar }),
  onClickSidebar: () => set((state) => ({ showSidebar: !state.showSidebar })),
  showSubtitle: false,
  setShowSubtitle: (showSubtitle: boolean) => set({ showSubtitle }),
  onClickSubtitle: () =>
    set((state) => ({ showSubtitle: !state.showSubtitle })),
  isDevMode: false,
  setIsDevMode: (isDevMode: boolean) => set({ isDevMode }),
  isRTCCompatible: true,
  setIsRTCCompatible: (isRTCCompatible: boolean) => set({ isRTCCompatible }),
  showCompatibilityDialog: false,
  setShowCompatibilityDialog: (showCompatibilityDialog: boolean) =>
    set({ showCompatibilityDialog }),
  showTimeoutDialog: false,
  setShowTimeoutDialog: (showTimeoutDialog: boolean) =>
    set({ showTimeoutDialog }),
  showLoginPanel: false,
  setShowLoginPanel: (showLoginPanel: boolean) => set({ showLoginPanel })
}))

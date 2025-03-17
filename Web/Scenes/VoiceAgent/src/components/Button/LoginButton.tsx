'use client'

import * as React from 'react'
import { useRouter } from 'next/navigation'
import { useTranslations } from 'next-intl'

import { Button, ButtonProps } from '@/components/ui/button'
import { useGlobalStore, useUserInfoStore } from '@/store'
import { cn } from '@/lib/utils'
import { LoadingSpinner } from '@/components/Icons'

const LOGIN_URL = `${process.env.NEXT_PUBLIC_DEMO_SERVER_URL}/v1/convoai/sso/login`

export function LoginButton(props: ButtonProps) {
  const { className, onClick, ...rest } = props

  const router = useRouter()
  const tLogin = useTranslations('login')
  const { globalLoading } = useUserInfoStore()

  const handleSSOLogin = () => {
    router.push(`${LOGIN_URL}?redirect_uri=${window.location.origin}/`)
  }

  return (
    <Button
      variant="info"
      size="icon"
      onClick={(e) => {
        if (onClick) {
          onClick(e)
        } else {
          handleSSOLogin()
        }
      }}
      disabled={globalLoading}
      {...rest}
      className={cn('w-fit gap-0 px-4 py-2 [&_svg]:size-6', className)}
    >
      {globalLoading && <LoadingSpinner />}
      {tLogin('title')}
    </Button>
  )
}

export function LoginPanelButton(props: ButtonProps) {
  const { className, ...rest } = props

  const { setShowLoginPanel } = useGlobalStore()
  const tLogin = useTranslations('login')
  const { globalLoading } = useUserInfoStore()

  const handleClick = () => {
    setShowLoginPanel(true)
  }

  return (
    <Button
      variant="info"
      size="icon"
      onClick={handleClick}
      disabled={globalLoading}
      {...rest}
      className={cn('w-fit gap-0 px-4 py-2 [&_svg]:size-6 bg-white text-icontext-inverse', className)}
    >
      {globalLoading && <LoadingSpinner />}
      {tLogin('title')}
    </Button>
  )
}

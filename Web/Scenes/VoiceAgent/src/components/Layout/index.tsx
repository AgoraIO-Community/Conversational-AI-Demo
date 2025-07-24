import type * as React from 'react'

import { Header } from '@/components/Layout/Header'
import { cn } from '@/lib/utils'

export const Layout = (props: {
  children?: React.ReactNode
  className?: string
}) => {
  const { children, className } = props
  return (
    <div
      className={cn(
        'flex min-h-dvh flex-col gap-[var(--ag-body-padding)] p-[var(--ag-body-padding)]',
        className
      )}
    >
      <Header />
      <main className='flex h-[var(--ag-main-min-height)] flex-col gap-[var(--ag-body-padding)] overflow-hidden'>
        {children}
      </main>
    </div>
  )
}

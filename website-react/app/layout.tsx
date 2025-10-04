import type { Metadata } from 'next'
import { Inter, DM_Sans, Poppins } from 'next/font/google'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
})

const dmSans = DM_Sans({
  subsets: ['latin'],
  weight: ['400', '500', '700', '900'],
  variable: '--font-dm-sans',
  display: 'swap',
})

const poppins = Poppins({
  subsets: ['latin'],
  weight: ['400', '600', '700', '900'],
  variable: '--font-poppins',
  display: 'swap',
})

export const metadata: Metadata = {
  title: 'AgentChains.ai - Screenshot → AI analyzes → copied to clipboard → just paste',
  description: 'Reply to anything by taking a screenshot. AgentChains.ai reads the screen, crafts the answer, and puts it on your clipboard instantly. Works with WhatsApp, iMessage, Instagram, LinkedIn, and any app.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={`${inter.variable} ${dmSans.variable} ${poppins.variable} font-sans antialiased`}>
        {children}
      </body>
    </html>
  )
}

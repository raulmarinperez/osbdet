import Link from 'next/link'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'OSBDET v2026r1',
  description: 'Open Source Big Data Educational Toolkit',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        {children}
      {/* Footer */}
      <section className="bg-slate-200 body-font">
        <div className="container px-5 py-5 mx-auto">
          <div className="grid grid-cols-6 gap-2 relative w-full z-10">
            <div className="col-span-4">
              <div className="flex flex-col relative gap-2 h-full w-full pr-20">
                <h1 className="text-2xl font-bold mb-2">About OSBDET</h1>
                <p><Link href="https://github.com/raulmarinperez/osbdet" className="underline" target="_blank">OSBDET</Link> is a tool for 
                creating test environments that simplifies building sandboxes integrating various open-source technologies. These environments 
                are designed for individuals looking to take their first steps with Big Data technologies effortlessly.</p>
                <p>OSBDET&apos;s architecture promotes extensibility, allowing users to integrate new frameworks with minimal effort.</p>
              </div>
            </div>
            <div className="col-span-2">
              <div className="flex flex-col relative h-full w-full">
                <h1 className="text-2xl font-bold mb-2">Follow</h1>
                <div className="flex flex-row relative gap-2 h-full w-full">
                  <Link title="OSBDET's Github repository" href="https://github.com/raulmarinperez/osbdet" target="_blank"><img src="/images/github.png" className="w-[24px] hover:drop-shadow-md"/></Link>
                  <Link title="Raúl Marín's LinkedIn profile" href="https://www.linkedin.com/in/raulmarinperez/" target="_blank"><img src="/images/linkedin.png" className="w-[24px] hover:drop-shadow-md"/></Link>
                  <Link title="Raúl Marín's Mastodon profile" href="https://mastodon.social/@thebsdprof" target="_blank"><img src="/images/mastodon.png" className="w-[24px] hover:drop-shadow-md"/></Link>
                </div>
              </div>
            </div>
          </div>
          <div className="mt-10 text-sm italic">
            <p>&copy; OSBDET 2026. All rights reserved - Web application built with <Link href="https://nextjs.org/" className="underline"  target="_blank">NextJS</Link>.</p>
          </div>
        </div>
      </section>
      </body>
    </html>
  )
}

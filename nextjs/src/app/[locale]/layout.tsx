import type { Metadata } from "next";
import localFont from "next/font/local";
import { NextIntlClientProvider } from 'next-intl';
import { getMessages } from 'next-intl/server';
import { notFound } from 'next/navigation';
import { routing } from '@/i18n/routing';
import { QueryProvider } from '@/providers/query-provider';
import "../globals.css";

const kufiFont = localFont({
  src: "../../../public/fonts/Kufi.ttf",
  variable: "--font-kufi",
});

const elMessiriFont = localFont({
  src: "../../../public/fonts/ElMessiri.ttf",
  variable: "--font-messiri",
});

export const metadata: Metadata = {
  title: "Sora",
  description: "Sora Storefront",
};

export default async function RootLayout({
  children,
  params
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  
  if (!routing.locales.includes(locale as (typeof routing.locales)[number])) {
    notFound();
  }

  const messages = await getMessages();

  // Arabic is right-to-left
  const dir = locale === 'ar' ? 'rtl' : 'ltr';

  return (
    <html
      lang={locale}
      dir={dir}
      className={`${kufiFont.variable} ${elMessiriFont.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col font-sans bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-50">
        <NextIntlClientProvider messages={messages}>
          <QueryProvider>
            {children}
          </QueryProvider>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}

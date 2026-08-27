import {useTranslations} from 'next-intl';
import Image from 'next/image';

export default function HomePage() {
  const t = useTranslations('Home');
  return (
    <main className="flex flex-col items-center justify-center flex-1 p-8">
      <Image src="/images/logo.png" alt="Sora Logo" width={150} height={150} className="mb-8" />
      <h1 className="text-4xl font-messiri font-bold">{t('title')}</h1>
    </main>
  );
}

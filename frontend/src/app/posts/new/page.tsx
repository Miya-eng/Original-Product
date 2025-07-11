'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import PostForm from '@/components/PostForm';
import Sidebar from '@/components/Sidebar';

export default function NewPostPage() {
  const router = useRouter();

  useEffect(() => {
    // ログインチェック
    const token = localStorage.getItem('accessToken');
    if (!token) {
      router.push('/login');
    }
  }, [router]);

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 px-8 py-10">
        <PostForm />
      </main>
    </div>
  );
}
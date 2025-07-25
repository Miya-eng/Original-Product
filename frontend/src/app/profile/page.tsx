'use client';

import { useEffect, useState } from 'react';
import axios from 'axios';
import Sidebar from '@/components/Sidebar';

type UserProfile = {
  username: string;
  email: string;
  residence_prefecture: string;
  residence_city: string;
  // 他に表示したい項目があればここに追加
};

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api';

export default function ProfilePage() {
  const [user, setUser] = useState<UserProfile | null>(null);

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const token = localStorage.getItem('accessToken');
        const res = await axios.get(`${API_BASE_URL}/users/me/`, {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });
        setUser(res.data);
      } catch {
        setUser(null);
        // 401エラーなら未ログインなのでリダイレクト等も可能
      }
    };
    fetchProfile();
  }, []);

  if (!user) {
    return <div className="p-8">ユーザー情報を取得できませんでした。</div>;
  }

  return (
    <div className="flex">
      <Sidebar />
      <div className="flex-1 flex items-start justify-center mt-10">
        <div className="bg-white shadow rounded-lg p-6 w-full max-w-xl">
        <h1 className="text-2xl font-bold mb-4">プロフィール</h1>
        <div className="mb-3 flex items-center">
          <div className="w-14 h-14 bg-gray-200 rounded-full flex items-center justify-center text-3xl mr-4">
            {/* ユーザーアイコン: イニシャル表示例 */}
            {user.username.charAt(0).toUpperCase()}
          </div>
          <div>
            <div className="text-lg font-semibold">{user.username}</div>
            <div className="text-gray-500 text-sm">{user.email}</div>
          </div>
        </div>
        <div className="mt-4">
          <div className="mb-1">
            <span className="font-bold">居住地：</span>
            {user.residence_prefecture} {user.residence_city}
          </div>
          {/* 他にも「投稿数」や「訪れたスポット数」などもAPI拡張で表示可能 */}
        </div>
        </div>
      </div>
    </div>
  );
}

'use client';

import { useEffect, useState } from 'react';
import Sidebar from '@/components/Sidebar';
import PostCard from '@/components/PostCard';
import { getPosts } from '@/api/posts';

interface Post {
  id: number;
  title: string;
  body: string;
  image?: string;
  city: string;
  user: {
    id: number;
    username: string;
    email: string;
  };
  latitude: number;
  longitude: number;
  created_at: string;
  like_count: number;
  is_liked: boolean;
}

export default function HomePage() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchPosts();
  }, []);

  const fetchPosts = async () => {
    try {
      const token = localStorage.getItem('accessToken');
      const data = await getPosts(token || undefined);
      setPosts(data);
    } catch (err) {
      setError('投稿の取得に失敗しました');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 px-8 py-10">
        <h2 className="text-2xl font-bold mb-6">地元の投稿</h2>
        
        {loading && (
          <div className="flex justify-center items-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-gray-900"></div>
          </div>
        )}
        
        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}
        
        {!loading && !error && posts.length === 0 && (
          <div className="text-center py-10 text-gray-500">
            まだ投稿がありません
          </div>
        )}
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {posts.map((post) => (
            <PostCard key={post.id} post={post} />
          ))}
        </div>
      </main>
    </div>
  );
}
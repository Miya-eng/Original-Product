'use client';

import { useState, useEffect } from 'react';
import { Search as SearchIcon } from 'lucide-react';
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

export default function SearchPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [posts, setPosts] = useState<Post[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  // 初回ロード時に全ての投稿を取得
  useEffect(() => {
    const fetchInitialPosts = async () => {
      try {
        setIsLoading(true);
        const token = localStorage.getItem('accessToken');
        const data = await getPosts(token || undefined);
        setPosts(data);
      } catch (error) {
        console.error('Failed to fetch posts:', error);
      } finally {
        setIsLoading(false);
      }
    };
    fetchInitialPosts();
  }, []);

  // 検索実行
  const handleSearch = async () => {
    if (searchQuery.trim() === '') {
      // 空の検索の場合は全件取得
      try {
        setIsLoading(true);
        const token = localStorage.getItem('accessToken');
        const data = await getPosts(token || undefined);
        setPosts(data);
      } catch (error) {
        console.error('Failed to fetch posts:', error);
      } finally {
        setIsLoading(false);
      }
    } else {
      // 検索クエリがある場合
      try {
        setIsLoading(true);
        const token = localStorage.getItem('accessToken');
        const data = await getPosts(token || undefined, searchQuery);
        setPosts(data);
      } catch (error) {
        console.error('Failed to search posts:', error);
      } finally {
        setIsLoading(false);
      }
    }
  };

  // Enterキーで検索実行
  const handleKeyPress = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      handleSearch();
    }
  };

  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <main className="flex-1 px-8 py-10">
        <div className="max-w-4xl mx-auto">
          <h1 className="text-3xl font-bold mb-8">投稿を検索</h1>
          
          {/* 検索ボックス */}
          <div className="relative mb-8">
            <div className="flex gap-2">
              <div className="relative flex-1">
                <SearchIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                <input
                  type="text"
                  placeholder="タイトル、本文、場所、ユーザー名で検索..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyPress={handleKeyPress}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <button
                onClick={handleSearch}
                disabled={isLoading}
                className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 transition-colors"
              >
                検索
              </button>
            </div>
          </div>

          {/* 検索結果 */}
          {isLoading ? (
            <div className="text-center py-8">
              <p className="text-gray-500">読み込み中...</p>
            </div>
          ) : (
            <>
              <p className="text-gray-600 mb-4">
                {searchQuery ? `"${searchQuery}" の検索結果: ${posts.length}件` : `全ての投稿: ${posts.length}件`}
              </p>
              
              {posts.length === 0 ? (
                <div className="text-center py-8">
                  <p className="text-gray-500">
                    {searchQuery ? '検索結果が見つかりませんでした。' : '投稿がありません。'}
                  </p>
                </div>
              ) : (
                <div className="grid gap-6 md:grid-cols-2">
                  {posts.map((post) => (
                    <PostCard key={post.id} post={post} />
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      </main>
    </div>
  );
}
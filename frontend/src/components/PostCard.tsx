'use client';

import { MapPin, Heart, MessageCircle, Calendar } from 'lucide-react';
import { useState } from 'react';
import Image from 'next/image';
import { togglePostLike } from '@/api/posts';
import CommentSection from './CommentSection';

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

type PostCardProps = {
  post: Post;
};

export default function PostCard({ post }: PostCardProps) {
  const [isLiked, setIsLiked] = useState(post.is_liked);
  const [likeCount, setLikeCount] = useState(post.like_count);
  const [isLiking, setIsLiking] = useState(false);
  const [showComments, setShowComments] = useState(false);

  const handleLike = async () => {
    const token = localStorage.getItem('accessToken');
    if (!token) {
      alert('いいねするにはログインが必要です');
      return;
    }

    if (isLiking) return;
    setIsLiking(true);

    // 楽観的更新
    const newIsLiked = !isLiked;
    const newLikeCount = isLiked ? likeCount - 1 : likeCount + 1;
    setIsLiked(newIsLiked);
    setLikeCount(newLikeCount);

    try {
      await togglePostLike(post.id, token);
    } catch (err) {
      // エラーが発生した場合、元の状態に戻す
      setIsLiked(!newIsLiked);
      setLikeCount(isLiked ? likeCount - 1 : likeCount + 1);
      console.error('いいねに失敗しました:', err);
      alert('いいねに失敗しました。もう一度お試しください。');
    } finally {
      setIsLiking(false);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('ja-JP', {
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
    });
  };

  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow">
      {/* 画像表示 */}
      {post.image && (
        <div className="relative aspect-w-16 aspect-h-9 bg-gray-200 h-48">
          <Image
            src={`http://localhost:8000${post.image}`}
            alt={post.title}
            fill
            className="object-cover"
            sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
          />
        </div>
      )}
      
      <div className="p-4">
        {/* タイトルと場所 */}
        <h3 className="font-bold text-lg mb-2">{post.title}</h3>
        <div className="flex items-center text-sm text-gray-500 mb-2">
          <MapPin className="w-4 h-4 mr-1" />
          <span>{post.city}</span>
        </div>
        
        {/* 投稿内容 */}
        <p className="text-gray-700 text-sm mb-3 line-clamp-3">{post.body}</p>
        
        {/* ユーザー情報と日付 */}
        <div className="flex items-center justify-between text-sm text-gray-500 mb-3">
          <span>@{post.user.username}</span>
          <div className="flex items-center">
            <Calendar className="w-4 h-4 mr-1" />
            <span>{formatDate(post.created_at)}</span>
          </div>
        </div>
        
        {/* アクションボタン */}
        <div className="flex items-center space-x-4 pt-3 border-t">
          <button
            onClick={handleLike}
            disabled={isLiking}
            className={`flex items-center space-x-1 transition-colors ${
              isLiked ? 'text-red-500' : 'text-gray-500 hover:text-red-500'
            }`}
          >
            <Heart className={`w-5 h-5 ${isLiked ? 'fill-current' : ''}`} />
            <span className="text-sm">{likeCount}</span>
          </button>
          
          <button 
            onClick={() => setShowComments(true)}
            className="flex items-center space-x-1 text-gray-500 hover:text-blue-500 transition-colors"
          >
            <MessageCircle className="w-5 h-5" />
            <span className="text-sm">コメント</span>
          </button>
        </div>
      </div>
      
      {/* コメントセクション */}
      <CommentSection 
        postId={post.id}
        isOpen={showComments}
        onClose={() => setShowComments(false)}
      />
    </div>
  );
}
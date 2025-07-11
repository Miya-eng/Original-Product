'use client';

import { useState, useEffect } from 'react';
import { Heart, Trash2, Send } from 'lucide-react';
import { getComments, createComment, deleteComment, toggleCommentLike } from '@/api/posts';

interface Comment {
  id: number;
  body: string;
  user: {
    id: number;
    username: string;
  };
  created_at: string;
  like_count: number;
  is_liked: boolean;
}

interface CommentSectionProps {
  postId: number;
  isOpen: boolean;
  onClose: () => void;
}

export default function CommentSection({ postId, isOpen, onClose }: CommentSectionProps) {
  const [comments, setComments] = useState<Comment[]>([]);
  const [newComment, setNewComment] = useState('');
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [currentUserId, setCurrentUserId] = useState<number | null>(null);

  useEffect(() => {
    const fetchComments = async () => {
      setLoading(true);
      try {
        const response = await getComments(postId);
        setComments(response.data);
      } catch (error) {
        console.error('コメントの取得に失敗しました:', error);
      } finally {
        setLoading(false);
      }
    };

    if (isOpen) {
      fetchComments();
      // ログインユーザーのIDを取得（簡易実装）
      const token = localStorage.getItem('accessToken');
      if (token) {
        try {
          const payload = JSON.parse(atob(token.split('.')[1]));
          setCurrentUserId(payload.user_id);
        } catch (error) {
          console.error('Token parsing error:', error);
        }
      }
    }
  }, [isOpen, postId]);

  const fetchComments = async () => {
    setLoading(true);
    try {
      const response = await getComments(postId);
      setComments(response.data);
    } catch (error) {
      console.error('コメントの取得に失敗しました:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmitComment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newComment.trim()) return;

    const token = localStorage.getItem('accessToken');
    if (!token) {
      alert('コメントするにはログインが必要です');
      return;
    }

    setSubmitting(true);
    try {
      await createComment(postId, newComment.trim(), token);
      setNewComment('');
      fetchComments(); // コメント一覧を再取得
    } catch (error) {
      console.error('コメントの投稿に失敗しました:', error);
      alert('コメントの投稿に失敗しました');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteComment = async (commentId: number) => {
    if (!confirm('このコメントを削除しますか？')) return;

    const token = localStorage.getItem('accessToken');
    try {
      await deleteComment(commentId, token);
      setComments(comments.filter(c => c.id !== commentId));
    } catch (error) {
      console.error('コメントの削除に失敗しました:', error);
      alert('コメントの削除に失敗しました');
    }
  };

  const handleLikeComment = async (commentId: number) => {
    const token = localStorage.getItem('accessToken');
    if (!token) {
      alert('いいねするにはログインが必要です');
      return;
    }

    try {
      await toggleCommentLike(commentId, token);
      setComments(comments.map(comment => 
        comment.id === commentId 
          ? {
              ...comment,
              is_liked: !comment.is_liked,
              like_count: comment.is_liked ? comment.like_count - 1 : comment.like_count + 1
            }
          : comment
      ));
    } catch (error) {
      console.error('いいねに失敗しました:', error);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('ja-JP', {
      month: 'numeric',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg max-w-md w-full max-h-[80vh] flex flex-col">
        {/* ヘッダー */}
        <div className="p-4 border-b flex justify-between items-center">
          <h3 className="text-lg font-semibold">コメント</h3>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700 text-xl"
          >
            ×
          </button>
        </div>

        {/* コメント一覧 */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {loading ? (
            <div className="text-center py-4">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-gray-900 mx-auto"></div>
            </div>
          ) : comments.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              まだコメントがありません
            </div>
          ) : (
            comments.map((comment) => (
              <div key={comment.id} className="border-b pb-3 last:border-b-0">
                <div className="flex justify-between items-start mb-1">
                  <span className="font-medium text-sm">@{comment.user.username}</span>
                  <div className="flex items-center space-x-2">
                    <span className="text-xs text-gray-500">{formatDate(comment.created_at)}</span>
                    {currentUserId === comment.user.id && (
                      <button
                        onClick={() => handleDeleteComment(comment.id)}
                        className="text-red-500 hover:text-red-700"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                </div>
                <p className="text-sm text-gray-700 mb-2">{comment.body}</p>
                <button
                  onClick={() => handleLikeComment(comment.id)}
                  className={`flex items-center space-x-1 text-xs transition-colors ${
                    comment.is_liked ? 'text-red-500' : 'text-gray-500 hover:text-red-500'
                  }`}
                >
                  <Heart className={`w-4 h-4 ${comment.is_liked ? 'fill-current' : ''}`} />
                  <span>{comment.like_count}</span>
                </button>
              </div>
            ))
          )}
        </div>

        {/* コメント投稿フォーム */}
        <div className="p-4 border-t">
          <form onSubmit={handleSubmitComment} className="flex space-x-2">
            <input
              type="text"
              value={newComment}
              onChange={(e) => setNewComment(e.target.value)}
              placeholder="コメントを入力..."
              className="flex-1 p-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={submitting}
            />
            <button
              type="submit"
              disabled={submitting || !newComment.trim()}
              className={`p-2 rounded-lg transition-colors ${
                submitting || !newComment.trim()
                  ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
                  : 'bg-blue-600 text-white hover:bg-blue-700'
              }`}
            >
              <Send className="w-5 h-5" />
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
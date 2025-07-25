import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api';

export const createPost = async (
  data: FormData | { title: string; body: string; latitude: number; longitude: number },
  token: string | null
) => {
  const headers: Record<string, string> = { Authorization: `Bearer ${token}` };
  
  // FormDataの場合はContent-Typeを設定しない（ブラウザが自動設定）
  if (!(data instanceof FormData)) {
    headers['Content-Type'] = 'application/json';
  }
  
  return await axios.post(`${API_BASE_URL}/posts/`, data, { headers });
};

export const getPosts = async (token?: string, searchQuery?: string) => {
  const headers: Record<string, string> = {};
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  
  const params: Record<string, string> = {};
  if (searchQuery) {
    params.q = searchQuery;
  }
  
  const response = await axios.get(`${API_BASE_URL}/posts/list/`, {
    headers,
    params
  });
  return response.data;
};

export const getMyPosts = async (token: string | null) => {
  return await axios.get(`${API_BASE_URL}/posts/myposts/`, {
    headers: { Authorization: `Bearer ${token}` },
  });
};

export const togglePostLike = async (postId: number, token: string | null) => {
  return await axios.post(`${API_BASE_URL}/posts/${postId}/like/`, {}, {
    headers: { Authorization: `Bearer ${token}` },
  });
};

// コメント関連API
export const getComments = async (postId: number) => {
  return await axios.get(`${API_BASE_URL}/posts/${postId}/comments/`);
};

export const createComment = async (postId: number, body: string, token: string | null) => {
  return await axios.post(`${API_BASE_URL}/posts/${postId}/comments/add/`, 
    { body }, 
    {
      headers: { Authorization: `Bearer ${token}` },
    }
  );
};

export const deleteComment = async (commentId: number, token: string | null) => {
  return await axios.delete(`${API_BASE_URL}/posts/comments/${commentId}/`, {
    headers: { Authorization: `Bearer ${token}` },
  });
};

export const toggleCommentLike = async (commentId: number, token: string | null) => {
  return await axios.post(`${API_BASE_URL}/posts/comments/${commentId}/like/`, {}, {
    headers: { Authorization: `Bearer ${token}` },
  });
};
